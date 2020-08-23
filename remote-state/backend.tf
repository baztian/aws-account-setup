terraform {
    backend "s3" {
        #aws sts get-caller-identity --query 'Account' --output text
        bucket = "terraform-state-982729519847-dev"
        key = "global/s3/terraform.tfstate"
        region = "eu-central-1"
        dynamodb_table = "terraform-state-lock-dev"
        encrypt = true
    }
}