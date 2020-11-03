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
