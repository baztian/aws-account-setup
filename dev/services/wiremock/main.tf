provider "aws" {
  region = "eu-central-1"
}

module "wiremock-ecs" {
  source = "../../../modules/services/wiremock-ecs"
  environment = "dev"
  wiremock_admin_password = var.wiremock_admin_password
}
