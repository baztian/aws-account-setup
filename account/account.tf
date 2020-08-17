module "iam_account" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-account"
  version = "~> 2.0"

  account_alias = "devbabowe2020"

  minimum_password_length = 12
}