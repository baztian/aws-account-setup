variable "service_name" {
    description = "Name of the service"
    type = string
    default = "example-wiremock"
}
variable "stage" {
    description = "Name of the stage where this service should get deployed to"
    type = string
    default = "dev"
}
variable "hosted_zone_name" {
    description = "Name of the hosted zone where this service will be available via DNS record"
    type = string
    default = "twenty.zonny.de"
}
variable "wiremock_admin_password" {
    description = "Password to access the admin api for wiremock"
}
