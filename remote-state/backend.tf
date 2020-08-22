terraform {
    backend "s3" {
        #aws sts get-caller-identity --query 'Account' --output text
        bucket = "982729519847-dev-terraform-state"
        key = "global/s3/terraform.tfstate"
        region = "eu-central-1"
        dynamodb_table = "dev-terraform-state-lock"
        encrypt = true
    }
}