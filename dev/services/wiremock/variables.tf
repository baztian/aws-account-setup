variable "cluster_name" {
  description = "The ECS cluster name"
  type        = string
  default = "complete-ecs"
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