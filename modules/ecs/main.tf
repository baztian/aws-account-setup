locals {
  name        = "${var.cluster_name}-${var.environment}"
  environment = var.environment

  # See https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_PortMapping.html
  # regarding the "ephemeral port range"
  ephemeral_port_from = 32768
  ephemeral_port_to = 65535

  # This is the convention we use to know what belongs to each other
  ec2_resources_name = local.name
}


#----- ECS --------
module "ecs" {
  source = "terraform-aws-modules/ecs/aws"
  version = "~> 2.8"

  name               = local.name
  container_insights = true

  capacity_providers = [aws_ecs_capacity_provider.ec2provider.name, "FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy = [
    {
      capacity_provider = aws_ecs_capacity_provider.ec2provider.name
      weight = 1
    }
  ]

  tags = {
    Environment = local.environment
  }
}

module "ec2_profile" {
  source = "terraform-aws-modules/ecs/aws//modules/ecs-instance-profile"
  version = "~> 2.8"

  name = local.name
  include_ssm = true

  tags = {
    Environment = local.environment
  }
}

resource "aws_ecs_capacity_provider" "ec2provider" {
  name = "ec2-provider-${local.name}"

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
  name_prefix = "ecs-cluster-sg-${local.name}-"
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

resource aws_security_group_rule "cluster_services_sg_rule" {
  description = "Allow traffic to the services of the cluster that are in the ephemeral port range"
  type = "ingress"
  from_port   = local.ephemeral_port_from
  to_port     = local.ephemeral_port_to
  protocol    = "tcp"
  security_group_id = aws_security_group.ecs_cluster_sg.id
  source_security_group_id = var.source_security_group_id
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.8"

  name = local.ec2_resources_name

  # Launch configuration
  lc_name = local.ec2_resources_name

  image_id             = data.aws_ami.amazon_linux_ecs.id
  instance_type        = "t3.micro"
  security_groups      = [aws_security_group.ecs_cluster_sg.id]
  iam_instance_profile = module.ec2_profile.this_iam_instance_profile_id
  user_data            = templatefile("${path.module}/templates/user-data.sh",
                                      {
                                        cluster_name = local.name
                                        disable_metrics = var.ecs_disable_metrics
                                        additional_user_data = var.additional_user_data
                                      }
                                     )
  key_name = var.key_name

  root_block_device = [
    {
      volume_size = 30
      volume_type = "gp2"
      delete_on_termination = true
      encrypted = true
    },
  ]

  # Auto scaling group
  asg_name                  = local.ec2_resources_name
  vpc_zone_identifier       = var.subnet_ids
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
