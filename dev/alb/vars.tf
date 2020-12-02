variable "alb_name" {
    description = "Name of this ALB"
    type = string
    default = "www"
}
variable "stage" {
    description = "Name of the stage where this ALB should get deployed to"
    type = string
    default = "dev"
}
variable "hosted_zone_name" {
    description = "Name of the hosted zone where this ALB will be available via DNS record"
    type = string
    default = "twenty.zonny.de"
}