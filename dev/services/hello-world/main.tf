provider "aws" {
  region = "eu-central-1"
}

locals {
  name = "helloworld"
}

data "aws_region" "current" {}

data "aws_vpc" "default" {
  default = true
}

resource "aws_cloudwatch_log_group" "hello_world" {
  name              = local.name
  retention_in_days = 1
}

resource "aws_ecs_task_definition" "hello_world" {
  family = local.name

  container_definitions = <<EOF
[
  {
    "name": "${local.name}",
    "image": "httpd:2.4",
    "cpu": 0,
    "memory": 300,
    "entryPoint": [
        "sh",
        "-c"
    ],
    "portMappings": [
        {
            "hostPort": 0,
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
  port = 80
  target_type = "instance"
  vpc_id = data.aws_vpc.default.id
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
  priority     = 100

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


data "aws_lb_listener" "www_https" {
  load_balancer_arn = data.aws_lb.www_lb.arn
  port = 443
}

resource "aws_lb_listener_rule" "https_forward_rule" {
  listener_arn = data.aws_lb_listener.www_https.arn
  priority     = 100

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

data "aws_ecs_cluster" "ecs_cluster" {
  cluster_name = var.cluster_name
}

resource "aws_ecs_service" "hello_world" {
  name            = local.name
  cluster         = data.aws_ecs_cluster.ecs_cluster.cluster_name
  task_definition = aws_ecs_task_definition.hello_world.arn

  desired_count = 1

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  load_balancer {
    target_group_arn = aws_lb_target_group.http_target_group.arn
    container_name = local.name
    container_port = 80
  }
}
