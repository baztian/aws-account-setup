provider "aws" {
  region = "eu-central-1"
}

locals {
  name = "wiremock"
}

data "aws_region" "current" {}

data "aws_vpc" "default" {
  default = true
}

resource "aws_cloudwatch_log_group" "wiremock" {
  name              = local.name
  retention_in_days = 1
}

resource aws_security_group_rule "simple_app_sg_rule" {
  description = "Allow HTTP traffic to simple-app"
  type = "ingress"
  from_port   = 81
  to_port     = 81
  protocol    = "tcp"
  security_group_id = var.ecs_cluster_security_group_id
  source_security_group_id = var.source_security_group_id
}

resource "aws_ecs_task_definition" "wiremock" {
  family = local.name

  container_definitions = <<EOF
[
  {
    "name": "${local.name}",
    "image": "rodolpheche/wiremock",
    "cpu": 0,
    "memory": 300,
    "portMappings": [
        {
            "hostPort": 81,
            "protocol": "tcp",
            "containerPort": 8080
        }
    ],
    "command": [
        "--admin-api-basic-auth",
        "admin:${var.wiremock_admin_password}"
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-group": "${local.name}",
        "awslogs-stream-prefix": "complete-ecs"
      }
    }
  }
]
EOF
}

resource "aws_lb_target_group" "http_target_group" {
  name = "${local.name}-target-group"
  # protocol used by the target
  protocol = "HTTP"
  # port exposed by the target
  port = 81
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

resource "aws_lb_listener_rule" "http_forward_rule" {
  listener_arn = var.alb_http_listener_arn
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http_target_group.arn
  }

  condition {
    host_header {
      values = ["${local.name}.twenty.zonny.de"]
    }
  }
}

resource "aws_lb_listener_rule" "https_forward_rule" {
  listener_arn = var.alb_https_listener_arn
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http_target_group.arn
  }

  condition {
    host_header {
      values = ["${local.name}.twenty.zonny.de"]
    }
  }
}

resource "aws_ecs_service" "wiremock" {
  name            = local.name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.wiremock.arn

  desired_count = 1

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  load_balancer {
    target_group_arn = aws_lb_target_group.http_target_group.arn
    container_name = local.name
    container_port = 8080
  }
}
