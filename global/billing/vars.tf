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
variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to all resources"
  default     = {}
}