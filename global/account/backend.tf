terraform {
  backend "s3" {
    region         = "eu-central-1"
    bucket         = "982729519847-global-terraform-state"
    key            = "global/account.tfstate"
    dynamodb_table = "982729519847-global-terraform-state-lock"
    encrypt        = "true"
  }
}
