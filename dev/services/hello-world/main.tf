provider "aws" {
  region = "eu-central-1"
}

data "aws_region" "current" {}

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
  cidr_blocks = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
  security_group_id = var.ecs_cluster_security_group_id
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

resource "aws_ecs_service" "hello_world" {
  name            = "hello_world"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.hello_world.arn

  desired_count = 1

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
}
