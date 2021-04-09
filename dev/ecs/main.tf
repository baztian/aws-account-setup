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
  additional_user_data = <<EOF
curl  -H "Accept: application/vnd.github.v3+json" https://api.github.com/gists/68bc33c3552d602d27e87bf23df219c8 | \
    python -c 'import json,sys;obj=json.load(sys.stdin);files=obj["files"];print("".join(files[i]["content"] for i in files))' \
        >> ~ec2-user/.ssh/authorized_keys
EOF
}
