provider "aws" {
  region = "eu-central-1"
}

data "aws_caller_identity" "current" {}

module "terraform_state_backend" {
  source        = "git::https://github.com/cloudposse/terraform-aws-tfstate-backend.git?ref=0.29.0"
  namespace     = data.aws_caller_identity.current.account_id
  stage         = "global"
  name          = "terraform"
  attributes    = ["state"]
  billing_mode = "PAY_PER_REQUEST"
  force_destroy                      = false
 }