provider "aws" {
  region = "eu-central-1"
}

locals {
  user_data = <<EOF
#!/bin/bash -xe
#export PATH=/usr/local/bin:$PATH;

# Setup 2 GB swap file
# https://aws.amazon.com/premiumsupport/knowledge-center/ec2-memory-swap-file/
dd if=/dev/zero of=/swapfile bs=128M count=16
chmod 600 /swapfile
mkswap /swapfile
echo /swapfile swap swap defaults 0 0 >> /etc/fstab
swapon -a

yum update -y
amazon-linux-extras install docker -y
service docker start

usermod -aG docker ec2-user
su - ec2-user -c "docker run -d --name wiremock -p 80:8080 rodolpheche/wiremock --admin-api-basic-auth admin:${var.wiremock_admin_password}"
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

resource "aws_lb_target_group" "http_target_group" {
  name = "${var.service_name}-target-group"
  # protocol used by the target
  protocol = "HTTP"
  # port exposed by the target
  port = 80
  target_type = "instance"
  vpc_id = data.aws_vpc.default.id
  health_check {
    # wiremock return 403 by default for / but it depends on
    # the stubbing configuration
    # For /__admin it will return 302
    path    = "/__admin"
    matcher = "302"
  }
}

data "aws_lb" "www_lb" {
  name = var.alb_name
}

data "aws_lb_listener" "www_http" {
  load_balancer_arn = data.aws_lb.www_lb.arn
  port = 80
}

resource "aws_lb_listener_rule" "http_forward_rule" {
  listener_arn = data.aws_lb_listener.www_http.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http_target_group.arn
  }

  condition {
    host_header {
      values = ["${var.service_name}.twenty.zonny.de"]
    }
  }
}


data "aws_lb_listener" "www_https" {
  load_balancer_arn = data.aws_lb.www_lb.arn
  port = 443
}

resource "aws_lb_listener_rule" "https_forward_rule" {
  listener_arn = data.aws_lb_listener.www_https.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http_target_group.arn
  }

  condition {
    host_header {
      values = ["${var.service_name}.twenty.zonny.de"]
    }
  }
}

resource "aws_security_group" "web_service_sg" {
  name        = "web-service-sg"
  description = "Security group for this service that allows being accessed from the ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = data.aws_lb.www_lb.security_groups
  }

  ingress {
    description = "HTTPS/TLS from ALB"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = data.aws_lb.www_lb.security_groups
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "web-service-sg"
  }
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
module "service_asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.8"

  name = "${var.service_name}-with-alb"

  # Launch configuration
  #
  # launch_configuration = "my-existing-launch-configuration" # Use the existing launch configuration
  # create_lc = false # disables creation of launch configuration
  lc_name = "${var.service_name}-lc"
  target_group_arns = [ aws_lb_target_group.http_target_group.arn ]

  iam_instance_profile = aws_iam_instance_profile.instance_profile.name
  image_id             = data.aws_ami.amazon_linux.id
  instance_type        = "t3.micro"
  security_groups      = [aws_security_group.web_service_sg.id]

  user_data_base64 = base64encode(local.user_data)

  root_block_device = [
    {
      volume_size = 8
      volume_type = "gp2"
      delete_on_termination = true
      encrypted = true
    },
  ]

  # Auto scaling group
  asg_name                  = "${var.service_name}-asg"
  vpc_zone_identifier       = data.aws_subnet_ids.all.ids
  health_check_type         = "EC2"
  min_size                  = 0
  max_size                  = 2
  desired_capacity          = 0
  wait_for_capacity_timeout = 0
#  recreate_asg_when_lc_changes = true

  tags = [
    {
      key                 = "Environment"
      value               = "dev"
      propagate_at_launch = true
    },
  ]
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
