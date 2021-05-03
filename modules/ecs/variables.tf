variable "cluster_name" {
  description = "Name of the cluster"
  type = string
  default = "cluster"
}
variable "environment" {
  description = "Name of the environment / stage where this service should get deployed to"
  type = string
  default = "dev"
}
variable "capacity_providers" {
  description = "List of short names of one or more capacity providers to associate with the cluster. Valid values also include FARGATE and FARGATE_SPOT."
  type        = list(string)
  default     = []
}
variable "default_capacity_provider_strategy" {
  description = "The capacity provider strategy to use by default for the cluster. Can be one or more."
  type        = list(map(any))
  default     = []
}