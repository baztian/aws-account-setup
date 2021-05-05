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

module "wiremock-ecs" {
  source = "../../../modules/services/wiremock-ecs"
  cluster_name = "cluster-dev"
  environment = "dev"
  base_domain_name = "twenty.zonny.de"
  wiremock_admin_password = var.wiremock_admin_password
  source_security_group_id = data.aws_security_group.source_sg.id
  subnet_ids = data.aws_subnet_ids.all.ids
#  assign_public_ip = true
#  capacity_provider_strategy = [{
#    capacity_provider = "FARGATE"
#    weight = 1
#    base = 0
#  }]
}
