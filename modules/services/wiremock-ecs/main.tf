provider "docker" {
}
data "docker_registry_image" "service_registry_image" {
  name = local.service_image
}
data "docker_registry_image" "ssl_proxy_registry_image" {
  name = local.ssl_proxy_image
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  default = true
}

resource "aws_cloudwatch_log_group" "cloudwatch_log_group" {
  name              = local.full_name
  retention_in_days = var.log_retention_in_days
}

resource "random_password" "wiremock_admin_password" {
  length = 16
  special = true
  min_special = 1
  override_special = "_%@"
}
resource "aws_ssm_parameter" "wiremock_admin_password" {
  name  = "/${local.full_name}/WIREMOCK_ADMIN_PASSWORD"
  type  = "SecureString"
  description = "Password for the wiremock admin user"
  value = random_password.wiremock_admin_password.result
  overwrite = false
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
  family = local.full_name
  requires_compatibilities = [ "EC2", "FARGATE" ]
  task_role_arn = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  network_mode = "awsvpc"
  cpu = 256
  memory = 512
  container_definitions = <<EOF
[
  {
    "name": "${local.full_name}",
    "image": "${local.service_image}@${data.docker_registry_image.service_registry_image.sha256_digest}",
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
    "secrets": [{
      "name": "WIREMOCK_ADMIN_PASSWORD",
      "valueFrom": "${aws_ssm_parameter.wiremock_admin_password.arn}"
    }],
    "command": [
        "sh",
        "-c",
        "java -cp /var/wiremock/lib/*:/var/wiremock/extensions/* com.github.tomakehurst.wiremock.standalone.WireMockServerRunner --admin-api-basic-auth admin:$${WIREMOCK_ADMIN_PASSWORD}"
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-group": "${local.full_name}",
        "awslogs-stream-prefix": "${local.name}"
      }
    }
  },
  {
    "name": "${local.ssl_proxy_container_name}",
    "image": "${local.ssl_proxy_image}@${data.docker_registry_image.ssl_proxy_registry_image.sha256_digest}",
    "cpu": 0,
    "memory": 100,
    "memoryReservation": 20,
    "portMappings": [
        {
            "hostPort": 443,
            "protocol": "tcp",
            "containerPort": 443
        }
    ],
    "environment": [
        {
            "name": "API_HOST",
            "value": "localhost"
        },
        {
            "name": "API_PORT",
            "value": "8080"
        }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-group": "${local.full_name}",
        "awslogs-stream-prefix": "${local.name}"
      }
    }
  }
]
EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "lb_target_group" {
  name = "${local.full_name}-target-group"
  # protocol used by the target
  protocol = "HTTPS"
  # port exposed by the target
  port = 443
  target_type = "ip"
  vpc_id = coalesce(var.alb_vpc_id, data.aws_vpc.default.id)
  health_check {
    protocol = "HTTPS"
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

data "aws_lb_listener" "www_https" {
  load_balancer_arn = data.aws_lb.www_lb.arn
  port = 443
}

resource "aws_lb_listener_rule" "https_forward_rule" {
  listener_arn = data.aws_lb_listener.www_https.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
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
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  security_group_id = aws_security_group.service_sg.id
  source_security_group_id = var.source_security_group_id
}

resource "time_sleep" "wait_for_iam_to_be_settled" {
  create_duration = "10s"
}

resource "aws_ecs_service" "ecs_service" {
  name            = local.full_name
  cluster         = data.aws_ecs_cluster.ecs_cluster.cluster_name
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn

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
    target_group_arn = aws_lb_target_group.lb_target_group.arn
    container_name = local.ssl_proxy_container_name
    container_port = 443
  }

  # work around https://github.com/hashicorp/terraform-provider-aws/issues/11351
  lifecycle {
    ignore_changes = [
      capacity_provider_strategy
    ]
  }
  depends_on = [aws_iam_role.ecs_task_role, time_sleep.wait_for_iam_to_be_settled]
}
