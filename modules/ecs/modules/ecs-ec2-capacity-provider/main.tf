locals {
  name        = "${var.name}-${var.environment}"
  environment = var.environment

  # See https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_PortMapping.html
  # regarding the "ephemeral port range"
  ephemeral_port_from = 32768
  ephemeral_port_to = 65535

  # This is the convention we use to know what belongs to each other
  ec2_resources_name = local.name
}

module "ec2_profile" {
  source = "terraform-aws-modules/ecs/aws//modules/ecs-instance-profile"
  version = "~> 3.1"

  name = local.name
  include_ssm = true
}

resource "aws_ecs_capacity_provider" "ec2provider" {
  name = local.name

  auto_scaling_group_provider {
    auto_scaling_group_arn = module.asg.autoscaling_group_arn
  }
}

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
  version = "~> 4.1"

  name = "${local.ec2_resources_name}-asg"

  # Launch template
  use_lt = true
  create_lt = true
  lt_name = local.ec2_resources_name
  update_default_version = true

  tag_specifications = [
    {
      resource_type = "instance"
      tags = {
        Environment = var.environment
      }
    },
    {
      resource_type = "volume"
      tags = {
        Environment = var.environment
      }
    }
  ]

  image_id             = data.aws_ami.amazon_linux_ecs.id
  instance_type        = var.instance_type
  security_groups      = [aws_security_group.ecs_cluster_sg.id]
  iam_instance_profile_arn = module.ec2_profile.iam_instance_profile_arn
  user_data_base64 = base64encode(templatefile("${path.module}/templates/user-data.sh",
  {
    cluster_name = var.cluster_name
    disable_metrics = var.ecs_disable_metrics
    additional_user_data = var.additional_user_data
  }
  )
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
  vpc_zone_identifier       = var.subnet_ids
  health_check_type         = "EC2"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  wait_for_capacity_timeout = 0

  tags = [
    {
      key                 = "Environment"
      value               = local.environment
      propagate_at_launch = true
    },
    {
      key                 = "Cluster"
      value               = var.cluster_name
      propagate_at_launch = true
    },
  ]
}
