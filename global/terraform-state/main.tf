provider "aws" {
  region = "eu-central-1"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

module "terraform_state_backend" {
  source        = "git::https://github.com/cloudposse/terraform-aws-tfstate-backend.git?ref=0.21.0"
  namespace     = data.aws_caller_identity.current.account_id
  stage         = "global"
  name          = "terraform"
  attributes    = ["state"]
  region        = data.aws_region.current.name
  billing_mode = "PAY_PER_REQUEST"
  force_destroy                      = false
 }