provider "aws" {
  region = "eu-central-1"
}

locals {
  user_data = <<EOF
#!/bin/bash -xe
#export PATH=/usr/local/bin:$PATH;
whoami

yum update -y
amazon-linux-extras install docker -y
service docker start

usermod -aG docker ec2-user
su - ec2-user -c "docker run -d --name wiremock -p 80:8080 rodolpheche/wiremock"
#sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
#chmod +x /usr/local/bin/docker-compose
#chown root:docker /usr/local/bin/docker-compose
#cat <<HERE >/home/ec2-user/docker-compose.yml
#nginx:
#  image: nginx
#  ports:
#    - "80:80"
#HERE
#chown ec2-user:ec2-user /home/ec2-user/docker-compose.yml
#/usr/local/bin/docker-compose -f /home/ec2-user/docker-compose.yml up -d

EOF
}

##############################################################
# Data sources to get VPC, subnets and security group details
##############################################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

module "alb_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"

  name        = "http-sg"
  description = "Security group with HTTP ports open for everybody (IPv4 CIDR), egress ports are all world open"
  vpc_id      = data.aws_vpc.default.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
}

module "service_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"

  name        = "service-sg"
  description = "Security group for this service that allows being accessed from the ALB"
  vpc_id      = data.aws_vpc.default.id

  # work around https://github.com/terraform-aws-modules/terraform-aws-security-group/issues/191
  ingress_cidr_blocks = [data.aws_vpc.default.cidr_block]
  ingress_with_source_security_group_id = [
    {
      rule                     = "http-80-tcp",
      source_security_group_id = module.alb_sg.this_security_group_id
    },
  ]
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"

    values = [
      "amzn2-ami-hvm-*-x86_64-gp2",
    ]
  }

  filter {
    name = "owner-alias"

    values = [
      "amazon",
    ]
  }
}

######
# Launch configuration and autoscaling group
######
module "example_asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.0"

  name = "example-with-alb"

  # Launch configuration
  #
  # launch_configuration = "my-existing-launch-configuration" # Use the existing launch configuration
  # create_lc = false # disables creation of launch configuration
  lc_name = "example-lc"
  target_group_arns = module.alb.target_group_arns

  iam_instance_profile = aws_iam_instance_profile.instance_profile.name
  image_id             = data.aws_ami.amazon_linux.id
  instance_type        = "t3.micro"
  security_groups      = [module.service_sg.this_security_group_id]

  user_data_base64 = base64encode(local.user_data)

  ebs_block_device = [
    {
      device_name           = "/dev/xvdz"
      volume_type           = "gp2"
      volume_size           = "50"
      delete_on_termination = true
    },
  ]

  root_block_device = [
    {
      volume_size = "50"
      volume_type = "gp2"
    },
  ]

  # Auto scaling group
  asg_name                  = "example-asg"
  vpc_zone_identifier       = data.aws_subnet_ids.all.ids
  health_check_type         = "EC2"
  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 0
  wait_for_capacity_timeout = 0

  tags = [
    {
      key                 = "Environment"
      value               = "dev"
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = "megasecret"
      propagate_at_launch = true
    },
  ]
}

######
# ALB
######
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"

  name = "alb-example"

  vpc_id          = data.aws_vpc.default.id
  subnets         = data.aws_subnet_ids.all.ids
  security_groups = [module.alb_sg.this_security_group_id]

  target_groups = [
    {
      name_prefix      = "pref-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      health_check = {
        # wiremock return 403 by default for /
        # and 302 for /__admin
        path    = "/__admin"
        matcher = "200-399"
      }
    }
  ]

  http_tcp_listeners = [
    {
      port     = 80
      protocol = "HTTP"
      target_group_index = 0
    },
  ]

  tags = {
    Owner       = "user"
    Environment = "dev"
  }
}

# SessionManager
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy" "AmazonSSMManagedInstanceCore" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "role" {
  name = var.service_name
  path = "/"

  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "ssm_role_policy_attach" {
  role       = aws_iam_role.role.name
  policy_arn = data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.service_name}-${var.stage}-instance-profile"
  role = aws_iam_role.role.name
}
