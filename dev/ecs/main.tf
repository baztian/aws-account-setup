provider "aws" {
  region = "eu-central-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

locals {
  name        = var.cluster_name
  environment = var.environment

  # This is the convention we use to know what belongs to each other
  ec2_resources_name = "${local.name}-${local.environment}"
}

data "aws_availability_zones" "available" {
  state = "available"
}

#----- ECS --------
module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  name               = local.name
  container_insights = true

  capacity_providers = [aws_ecs_capacity_provider.prov1.name, "FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy = {
    capacity_provider = aws_ecs_capacity_provider.prov1.name # EC2
    weight = 1
  }

  tags = {
    Environment = local.environment
  }
}

module "ec2_profile" {
  source = "terraform-aws-modules/ecs/aws//modules/ecs-instance-profile"

  name = local.name
  include_ssm = true

  tags = {
    Environment = local.environment
  }
}

resource "aws_ecs_capacity_provider" "prov1" {
  name = "prov1"

  auto_scaling_group_provider {
    auto_scaling_group_arn = module.asg.this_autoscaling_group_arn
  }

}

#----- ECS  Resources--------

#For now we only use the AWS ECS optimized ami <https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html>
data "aws_ami" "amazon_linux_ecs" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

resource "aws_security_group" "ecs_cluster_sg" {
  name        = "ecs-cluster-sg"
  description = "Security group for the ecs cluster"

  egress {
    description = "Allow all outbound traffic."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ecs-cluster-sg"
  }
}

resource "aws_key_pair" "key_pair" {
  key_name = "${var.cluster_name}-${var.environment}"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDkDeDy0noq26Op+EikCXBh0ruIugAVv/5rXE/0obCwUMN3i9ZEiXdZ9YD8lZqlkt7LcqhtpuehJbTM6IYM4CkiXEyeD/GJHSlF/K3atAEefo48/QhPye+VzKwp77/7i1rw6Qpeu+Rhuf2ttF50cxOQdzkGH5s3HaPS3uVd4cRj8Yr9JPYPrXarwGSObJA9/ksjd9+Uqf2n4CmOItHccGl9sSiUbmS1RRiFrKxiDgh8QY0DbiO9m3u3B2riEcudMGfZnG7URh44RGPuJ/BM9ZTEHRbtdkOBz9JzbvMlvc/+27lYRPqxLRlo8xoB7q+jg/OqALni/MoeWeQcGOe7LCkX me@desktop"

  tags = {
    Environment = local.environment
  }
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.0"

  name = local.ec2_resources_name

  # Launch configuration
  lc_name = local.ec2_resources_name

  image_id             = data.aws_ami.amazon_linux_ecs.id
  instance_type        = "t3.micro"
  security_groups      = [aws_security_group.ecs_cluster_sg.id]
  iam_instance_profile = module.ec2_profile.this_iam_instance_profile_id
  user_data            = data.template_file.user_data.rendered
  key_name = aws_key_pair.key_pair.key_name

  # Auto scaling group
  asg_name                  = local.ec2_resources_name
  vpc_zone_identifier       = data.aws_subnet_ids.all.ids
  health_check_type         = "EC2"
  min_size                  = 0
  max_size                  = 2
  desired_capacity          = 1
  wait_for_capacity_timeout = 0

  tags = [
    {
      key                 = "Environment"
      value               = local.environment
      propagate_at_launch = true
    },
    {
      key                 = "Cluster"
      value               = local.name
      propagate_at_launch = true
    },
  ]
}

data "template_file" "user_data" {
  template = file("${path.module}/templates/user-data.sh")

  vars = {
    cluster_name = local.name
  }
}
