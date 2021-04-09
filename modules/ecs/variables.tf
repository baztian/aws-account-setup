variable "cluster_name" {
  description = "Name of the cluster. `-<environment>` will be appended"
  type = string
  default = "cluster"
}
variable "environment" {
  description = "Name of the environment / stage where this service should get deployed to"
  type = string
  default = "dev"
}
variable "subnet_ids" {
  description = "Ids of the securitygropus being used for the instances in the ECS EC2 autoscaling group"
  type = list
}
variable "key_name" {
  description = "The key name that should be used for the instances in the ECS EC2 autoscaling group"
  type        = string
  default     = null
}
variable "source_security_group_id" {
  description = "Id of the security group that will be allowed to access the ports opened by this cluster. Usually the security group of the ALB."
  type = string
}
variable "ecs_disable_metrics" {
  description = "Disable ECS metric data being [sent automatically to CloudWatch in 1-minute periods](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cloudwatch-metrics.html). Not disabling it costs extra money."
  type = bool
  default = true
}