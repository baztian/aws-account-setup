provider "aws" {
  region = "eu-central-1"
}

data "aws_region" "current" {}

data "aws_vpc" "default" {
  default = true
}

resource "aws_cloudwatch_log_group" "hello_world" {
  name              = "hello_world"
  retention_in_days = 1
}

resource aws_security_group_rule "simple_app_sg_rule" {
  description = "Allow HTTP traffic to simple-app"
  type = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  security_group_id = var.ecs_cluster_security_group_id
  source_security_group_id = var.source_security_group_id
}

resource "aws_ecs_task_definition" "hello_world" {
  family = "hello_world"

  container_definitions = <<EOF
[
  {
    "name": "simple-app",
    "image": "httpd:2.4",
    "cpu": 0,
    "memory": 300,
    "entryPoint": [
        "sh",
        "-c"
    ],
    "portMappings": [
        {
            "hostPort": 80,
            "protocol": "tcp",
            "containerPort": 80
        }
    ],
    "command": [
        "/bin/sh -c \"echo '<html> <head> <title>Amazon ECS Sample App</title> <style>body {margin-top: 40px; background-color: #333;} </style> </head><body> <div style=color:white;text-align:center> <h1>Amazon ECS Sample App</h1> <h2>Congratulations!</h2> <p>Your application is now running on a container in Amazon ECS.</p> </div></body></html>' >  /usr/local/apache2/htdocs/index.html && httpd-foreground\""
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-group": "hello_world",
        "awslogs-stream-prefix": "complete-ecs"
      }
    }
  }
]
EOF
}

resource "aws_lb_target_group" "http_target_group" {
  name_prefix = "pref-"
  # protocol used by the target
  protocol = "HTTP"
  # port exposed by the target
  port = 80
  target_type = "instance"
  vpc_id = data.aws_vpc.default.id
}

resource "aws_lb_listener_rule" "http_forward_rule" {
  listener_arn = var.alb_http_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http_target_group.arn
  }

  condition {
    host_header {
      values = ["sample-app.twenty.zonny.de"]
    }
  }
}

resource "aws_lb_listener_rule" "https_forward_rule" {
  listener_arn = var.alb_https_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http_target_group.arn
  }

  condition {
    host_header {
      values = ["sample-app.twenty.zonny.de"]
    }
  }
}

resource "aws_ecs_service" "hello_world" {
  name            = "hello_world"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.hello_world.arn

  desired_count = 1

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  load_balancer {
    target_group_arn = aws_lb_target_group.http_target_group.arn
    container_name = "simple-app"
    container_port = 80
  }
}
