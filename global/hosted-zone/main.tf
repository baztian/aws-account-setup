provider "aws" {
  region = "eu-central-1"
}

resource "aws_route53_zone" "my_hosted_zone" {
  name = var.domain_name
  tags = {
    Name : var.domain_name
  }
}

resource "aws_acm_certificate" "my_certificate_request" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.{var.domain_name}"]
  validation_method         = "DNS"

  tags = {
    Name : var.domain_name
  }

  lifecycle {
    create_before_destroy = true
  }
}
