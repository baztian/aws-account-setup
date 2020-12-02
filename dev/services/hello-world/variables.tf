variable "cluster_id" {
  description = "The ECS cluster ID"
  type        = string
}
variable "ecs_cluster_security_group_id" {
  description = "Id of the security group created for the ecs cluster. This id is intended to be used for extending with extra ingress rules using aws_security_group_rule resources."
  type = string
}