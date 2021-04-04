variable "service_name" {
    description = "Name of the service"
    type = string
    default = "ec2-wiremock"
}
variable "stage" {
    description = "Name of the stage where this service should get deployed to"
    type = string
    default = "dev"
}
variable "alb_name" {
    description = "Name of this ALB to which we will assign a listener rule to forward to this service."
    type = string
    default = "www"
}
variable "wiremock_admin_password" {
    description = "Password to access the admin api for wiremock"
}
