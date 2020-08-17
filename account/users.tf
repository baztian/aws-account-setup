module "iam_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "~> 2.0"

  name          = "dev-babowe"
  create_iam_user_login_profile = false # don't create user login to avoid gpg handling that I currently don't understand. https://stackoverflow.com/questions/53513795/pgp-key-in-terraform-for-aws-iam-user-login-profile
  # instead enable console password manually
  force_destroy = true

  password_reset_required = true
}

output "this_iam_access_key_id" {
  description = "The access key ID"
  value       = module.iam_user.this_iam_access_key_id
}

output "this_iam_access_key_secret" {
  description = "The access key secret"
  value       = module.iam_user.this_iam_access_key_secret
  sensitive   = true
}

data "aws_caller_identity" "current" {}

module "iam_assumable_roles" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-roles"
  version = "~> 2.0"

  trusted_role_arns = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/dev-babowe",
  ]

  create_admin_role = true

  create_poweruser_role = true
  poweruser_role_name   = "developer"

  create_readonly_role       = true
  readonly_role_requires_mfa = false
}
