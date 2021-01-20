variable "cluster_id" {
  description = "The ECS cluster ID"
  type        = string
}
variable "alb_http_listener_arn" {
  description = "ARN of the ALB HTTP listener to which we will assign a listener rule to forward to this service."
}
variable "alb_https_listener_arn" {
  description = "ARN of the ALB HTTPS listener to which we will assign a listener rule to forward to this service."
}
