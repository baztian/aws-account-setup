terraform {
  backend "s3" {
    region         = "eu-central-1"
    bucket         = "982729519847-dev-terraform-state"
    key            = "dev/wiremock.tfstate"
    dynamodb_table = "982729519847-dev-terraform-state-lock"
    encrypt        = "true"
  }
}
