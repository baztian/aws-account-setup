output "sns_topic_arn" {
  description = "SNS Topic ARN to be subscribed to in order to delivery the clodwatch billing alarms"
  value       = aws_sns_topic.budget_alerts.arn
}
