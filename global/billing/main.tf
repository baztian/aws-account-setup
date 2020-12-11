data "aws_iam_account_alias" "current" {}

# CloudWatch billing alerts must be in US-EAST-1
provider "aws" {
  version = "~> 2.0"
  region = "eu-central-1"
}

resource "aws_budgets_budget" "total_cost" {
  name = "${data.aws_iam_account_alias.current.account_alias}-total-costs"
  budget_type = "COST"
  limit_amount = "1"
  limit_unit = "USD"
  time_unit = "MONTHLY"
  time_period_start = "2019-01-01_00:00"
  notification {
    comparison_operator = "GREATER_THAN"
    threshold = 100
    threshold_type = "PERCENTAGE"
    notification_type = "FORECASTED"
    subscriber_email_addresses = var.budget_notification_emails
  }
}
