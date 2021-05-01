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

module "ecs-ec2-capacity-provider" {
  source = "../../modules/ecs/modules/ecs-ec2-capacity-provider"
  environment = var.environment
  name = "cluster-ec2-provider"
  subnet_ids = data.aws_subnet_ids.all.ids
  source_security_group_id = data.aws_security_group.source_sg.id
  additional_user_data = <<EOF
curl  -H "Accept: application/vnd.github.v3+json" https://api.github.com/gists/68bc33c3552d602d27e87bf23df219c8 | \
    python -c 'import json,sys;obj=json.load(sys.stdin);files=obj["files"];print("".join(files[i]["content"] for i in files))' \
        >> ~ec2-user/.ssh/authorized_keys
EOF
}

module "ecs" {
  source = "../../modules/ecs"
  cluster_name = var.cluster_name
  environment = var.environment
  capacity_providers = [module.ecs-ec2-capacity-provider.capacity_provider_name,
    "FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy = [
    {
      capacity_provider = module.ecs-ec2-capacity-provider.capacity_provider_name
      weight = 1
    }
  ]
}
