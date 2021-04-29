provider "docker" {
}
data "docker_registry_image" "wiremock" {
  name = local.image
}

locals {
  name = "wiremock"
  image = "rodolpheche/wiremock:2.27.2"
}

data "aws_region" "current" {}

data "aws_vpc" "default" {
  default = true
}

resource "aws_cloudwatch_log_group" "wiremock" {
  name              = "${local.name}-${var.environment}"
  retention_in_days = var.log_retention_in_days
}

resource "aws_ecs_task_definition" "wiremock" {
  family = "${local.name}-${var.environment}"
  requires_compatibilities = [ "EC2" ]
  task_role_arn = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = <<EOF
[
  {
    "name": "${local.name}-${var.environment}",
    "image": "${local.image}@${data.docker_registry_image.wiremock.sha256_digest}",
    "cpu": 0,
    "memory": 100,
    "memoryReservation": 20,
    "portMappings": [
        {
            "hostPort": 0,
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
        "awslogs-group": "${local.name}-${var.environment}",
        "awslogs-stream-prefix": "complete-ecs"
      }
    }
  }
]
EOF
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "http_target_group" {
  name = "${local.name}-${var.environment}-target-group"
  # protocol used by the target
  protocol = "HTTP"
  # port exposed by the target
  port = 80
  target_type = "instance"
  vpc_id = coalesce(var.alb_vpc_id, data.aws_vpc.default.id)
  health_check {
    # wiremock return 403 by default for / but it depends on
    # the stubbing configuration
    # For /__admin it will return 302
    path    = "/__admin"
    matcher = "302"
  }
  tags = {
    Environment = var.environment
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
      values = ["${local.name}-${var.environment}.twenty.zonny.de"]
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
      values = ["${local.name}-${var.environment}.twenty.zonny.de"]
    }
  }
}

data "aws_ecs_cluster" "ecs_cluster" {
  cluster_name = var.cluster_name
}

resource "time_sleep" "wait_for_iam_to_be_settled" {
  create_duration = "10s"
}

resource "aws_ecs_service" "wiremock" {
  name            = "${local.name}-${var.environment}"
  cluster         = data.aws_ecs_cluster.ecs_cluster.cluster_name
  task_definition = aws_ecs_task_definition.wiremock.arn

  desired_count = 1

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 0

  load_balancer {
    target_group_arn = aws_lb_target_group.http_target_group.arn
    container_name = "${local.name}-${var.environment}"
    container_port = 8080
  }

  # work around https://github.com/hashicorp/terraform-provider-aws/issues/11351
  lifecycle {
    ignore_changes = [
      capacity_provider_strategy
    ]
  }
  depends_on = [aws_iam_role.ecs_task_role, time_sleep.wait_for_iam_to_be_settled]
  tags = {
    Environment = var.environment
  }
}
