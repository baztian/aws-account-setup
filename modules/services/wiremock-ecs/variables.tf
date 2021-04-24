variable "cluster_name" {
  description = "The ECS cluster name"
  type        = string
  default = "cluster"
}
variable "alb_name" {
  description = "Name of the ALB to which we will assign a listener rule to forward to this service."
  type = string
  default = "www"
}
variable "wiremock_admin_password" {
  description = "Password to access the admin api for wiremock"
}
variable "environment" {
  description = "The (isolated) environment of this service"
  type = string
  default = "dev"
}
variable "log_retention_in_days" {
  description = "Retention time of the log group in days"
  type = number
  default = 1
}
variable "alb_vpc_id" {
  description = "VPC where this service' alb is running in - default vpc if not specified"
  type = string
  default = null
}