variable "cluster_name" {
  description = "Name of the cluster"
  type = string
  default = "complete-ecs"
}
variable "environment" {
  description = "Name of the environment / stage where this service should get deployed to"
  type = string
  default = "dev"
}
