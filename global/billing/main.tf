# CloudWatch billing alerts must be in US-EAST-1
provider "aws" {
  version = "~> 2.0"
  region = "eu-central-1"
}
resource "aws_budgets_budget" "total_cost" {
  name = "total-costs"
  budget_type = "COST"
  limit_amount = "1"
  limit_unit = "USD"
  time_unit = "MONTHLY"
  time_period_start = "2019-01-01_00:00"
}
