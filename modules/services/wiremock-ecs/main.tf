provider "docker" {
}
data "docker_registry_image" "wiremock" {
  name = local.image
}

locals {
  name = "wiremock"
  image = "rodolpheche/wiremock:2.27.2"
  host_header = "${local.name}-${var.environment}.twenty.zonny.de"
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
  requires_compatibilities = [ "EC2", "FARGATE" ]
  task_role_arn = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  network_mode = "awsvpc"
  cpu = 256
  memory = 512
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
            "hostPort": 8080,
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
  port = 8080
  target_type = "ip"
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
      values = [local.host_header]
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
      values = [local.host_header]
    }
  }
}

data "aws_ecs_cluster" "ecs_cluster" {
  cluster_name = var.cluster_name
}

resource "aws_security_group" "service_sg" {
  name_prefix = "service-sg-${local.name}-"
  description = "Security group for the ${local.name} service"

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

resource aws_security_group_rule "service_sg_rule" {
  description = "Allow traffic to the ${local.name} service"
  type = "ingress"
  from_port   = 8080
  to_port     = 8080
  protocol    = "tcp"
  security_group_id = aws_security_group.service_sg.id
  source_security_group_id = var.source_security_group_id
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

  dynamic "capacity_provider_strategy" {
    for_each = var.capacity_provider_strategy
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = capacity_provider_strategy.value.weight
      base              = lookup(capacity_provider_strategy.value, "base", null)
    }
  }

  network_configuration {
    security_groups  = [var.source_security_group_id, aws_security_group.service_sg.id]
    subnets          = var.subnet_ids
    assign_public_ip = var.assign_public_ip
  }

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
