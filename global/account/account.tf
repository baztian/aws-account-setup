module "iam_account" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-account"
  version = "~> 3.6"

  account_alias = "devbabowe2020"

  minimum_password_length = var.password_lenght
}

variable "password_lenght" {
  description = "Password length to be used in this account"
  type = number
  default = 12
}