provider "aws" {
  region = "eu-central-1"
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
  source = "terraform-aws-modules/security-group/aws"

  name        = "alb-sg"
  description = "Security group with HTTP(s) ports open for everybody (IPv4+v6 CIDR), egress ports are all world open"
  vpc_id      = data.aws_vpc.default.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_ipv6_cidr_blocks = ["::/0"]
  ingress_rules            = ["http-80-tcp","https-443-tcp"]
  ingress_with_self = [
    {
      rule = "all-all"
    },
  ]
  egress_rules      = ["all-all"]
}

resource "aws_lb" "this_alb" {
  name               = var.alb_name
  load_balancer_type = "application"

  subnets            = data.aws_subnet_ids.all.ids

  security_groups    = [module.alb_sg.this_security_group_id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this_alb.arn
  port              = 80
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this_alb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = data.aws_acm_certificate.issued.arn

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}
