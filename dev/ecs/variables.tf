variable "cluster_name" {
  description = "Name of the cluster"
  type = string
  default = "cluster-dev"
}
variable "environment" {
  description = "Name of the environment / stage where this service should get deployed to"
  type = string
  default = "dev"
}
variable "source_security_group_name" {
  description = "Name of the security group that will be allowed to access the ports opened by this cluster. Usually the security group of the ALB."
  type = string
  default = "alb-sg-*"
}
