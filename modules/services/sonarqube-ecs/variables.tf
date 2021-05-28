variable "source_security_group_id" {
  description = "Id of the security group that will be allowed to access the ports opened by this cluster. Usually the security group of the ALB."
  type = string
}
variable "subnet_ids" {
  description = "Ids of the subnets being used for the service"
  type = list
}

variable "alb_name" {
  description = "Name of the ALB to which we will assign a listener rule to forward to this service."
  type = string
  default = "www"
}
variable "alb_vpc_id" {
  description = "VPC where this service' alb is running in - default vpc if not specified"
  type = string
  default = null
}
variable "assign_public_ip" {
  description = "Fargate only: Assign a public IP address to the service network interface. Required if you want to run your service without a NAT. Defaults to false."
  type = string
  default = null
}
variable "base_domain_name" {
  description = "Base domain name. Defaults to ALB dns name."
  type = string
  default = null
}
variable "capacity_provider_strategy" {
  description = "Capacity provider strategy for this service. If not specified default capacity provider strategy will be used"
  type = list(object({
    capacity_provider = string
    weight = number
    base = number
  }))
  default = []
}
variable "cluster_name" {
  description = "The ECS cluster name"
  type        = string
  default = "cluster"
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

locals {
  name = "sonar"
  service_image = "sonarqube:lts-community"
  ssl_proxy_image = "baztian/nginx-snakeoil:latest"
  full_name = "${local.name}-${var.environment}"
  ssl_proxy_container_name = "${local.full_name}-ssl-proxy"
  host_header = "${local.full_name}.${coalesce(var.base_domain_name, data.aws_lb.www_lb.dns_name)}"
}
