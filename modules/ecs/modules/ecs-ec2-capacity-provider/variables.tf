variable "cluster_name" {
  description = "Name of the ecs cluster for wich this capacity provider is to be created"
  type = string
}
variable "name" {
  description = "Name of the capacity provider. `-<environment>` will be appended"
  type = string
  default = "ec2-provider"
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
variable "additional_user_data" {
  description = "Additional user-data shell code to be executed on instence creation"
  type = string
  default = ""
}
variable "instance_type" {
  description = "Type of the ec2 instance(s) being created in the asg."
  type = string
  default = "t3.micro"
}
variable "min_size" {
  description = "Minimum number of instances running in the asg."
  type = number
  default = 0
}
variable "max_size" {
  description = "Maximum number of instances running in the asg."
  type = number
  default = 2
}
variable "desired_capacity" {
  description = "Desired number of instances running in the asg."
  type = number
  default = 1
}
