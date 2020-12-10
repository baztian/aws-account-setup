variable "monthly_billing_threshold" {
  description = "Billing threshold per month in the currency selected via `currency`"
  type = string
  default = "0"
}
variable "currency" {
  description = "Billing currency"
  type = string
  default = "EUR"
}
variable "budget_notification_emails" {
  description = "To which e-mail adresses the notifications should be sent."
  type = list(string)
}
variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to all resources"
  default     = {}
}