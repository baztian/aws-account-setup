variable "wiremock_admin_password" {
  description = "Password to access the admin api for wiremock"
}
variable "source_security_group_name" {
  description = "Name of the security group that will be allowed to access the ports opened by this service. Usually the security group of the ALB."
  type = string
  default = "alb-sg-*"
}
