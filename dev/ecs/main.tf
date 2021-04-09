provider "aws" {
  region = "eu-central-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_security_group" "source_sg" {
  name = var.source_security_group_name
}

module "ecs" {
  source = "../../modules/ecs"
  cluster_name = var.cluster_name
  environment = var.environment
  subnet_ids = data.aws_subnet_ids.all.ids
  source_security_group_id = data.aws_security_group.source_sg.id
}
