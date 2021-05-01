locals {
  name        = "${var.cluster_name}-${var.environment}"
  environment = var.environment
}


module "ecs" {
  source = "terraform-aws-modules/ecs/aws"
  version = "~> 2.8"

  name               = local.name
  container_insights = true

  capacity_providers = var.capacity_providers

  default_capacity_provider_strategy = var.default_capacity_provider_strategy

  tags = {
    Environment = local.environment
  }
}
