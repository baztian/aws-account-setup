module "iam_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "~> 2.0"

  name          = "dev-babowe"
  # gpg --list-keys
  # gpg --export <email or id>|base64 > pubkey.gpg
  pgp_key = file("pubkey.gpg")
  create_iam_user_login_profile = true
  force_destroy = true
  password_length = var.password_lenght
  password_reset_required = false
}

output "this_iam_access_key_id" {
  description = "The access key ID"
  value       = module.iam_user.this_iam_access_key_id
}

output "this_iam_access_key_secret" {
  description = "The gpg encrypted and base64 encoded access key secret. Use base64 --decode|gpg --decrypt to decrypt the value."
  value       = module.iam_user.this_iam_access_key_encrypted_secret
}

output "this_iam_user_login_profile_encrypted_password" {
  description = "The gpg encrypted and base64 encoded encrypted login profile password. Use base64 --decode|gpg --decrypt to decrypt the value."
  value       = module.iam_user.this_iam_user_login_profile_encrypted_password
}

output "this_iam_user_gpg_fingerprint" {
  description = "The gpg fingerprint used to encrypt the secrets. Use gpg --fingerprint to list known fingerprints."
  value       = module.iam_user.this_iam_access_key_key_fingerprint
}

data "aws_caller_identity" "current" {}

module "iam_assumable_roles" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-roles"
  version = "~> 2.0"

  trusted_role_arns = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
  ]

  create_admin_role = true

  create_poweruser_role = true
  poweruser_role_name   = "developer"

  create_readonly_role       = true
  readonly_role_requires_mfa = false
}

module "iam_group_with_assumable_roles_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-group-with-assumable-roles-policy"
  version = "~> 2.0"

  name = "developers"

  assumable_roles = [
    module.iam_assumable_roles.admin_iam_role_arn,
    module.iam_assumable_roles.poweruser_iam_role_arn,
    module.iam_assumable_roles.readonly_iam_role_arn,
  ]

  group_users = [
    module.iam_user.this_iam_user_name
  ]
}