# CloudWatch billing alerts must be in US-EAST-1
provider "aws" {
  version = "~> 2.0"
#  region = "us-east-1"
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_metric_alarm" "account_billing" {
  alarm_name          = "account-billing-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"     # every 6 hours
  period              = "21600" # The period in seconds ~ 6 hours
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  statistic           = "Average"
  threshold           = var.monthly_billing_threshold
  alarm_description   = "Billing alarm account ${data.aws_caller_identity.current.id} >= ${var.currency} ${var.monthly_billing_threshold}"
  alarm_actions       = ["${aws_sns_topic.budget_alerts.arn}"]

  dimensions = {
    Currency      = var.currency
    LinkedAccount = data.aws_caller_identity.current.id
  }

  tags = var.tags
}

resource "aws_sns_topic" "budget_alerts" {
  name     = "billing-alarm-notification-${lower(var.currency)}"
  tags     = var.tags
}
