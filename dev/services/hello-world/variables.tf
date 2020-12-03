variable "cluster_id" {
  description = "The ECS cluster ID"
  type        = string
}
variable "ecs_cluster_security_group_id" {
  description = "Id of the security group created for the ecs cluster. This id is intended to be used for extending with extra ingress rules using aws_security_group_rule resources."
  type = string
}
variable "source_security_group_id" {
  description = "Id of the security group that will be allowed to access the ports opened by this service."
  type = string
}
variable "alb_http_listener_arn" {
  description = "ARN of the ALB HTTP listener to which we will assign a listener rule to forward to this service."
}
variable "alb_https_listener_arn" {
  description = "ARN of the ALB HTTPS listener to which we will assign a listener rule to forward to this service."
}
