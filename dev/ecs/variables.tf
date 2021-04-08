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
variable "ssh_public_key" {
  description = "SSH public key for EC2 instance access"
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDkDeDy0noq26Op+EikCXBh0ruIugAVv/5rXE/0obCwUMN3i9ZEiXdZ9YD8lZqlkt7LcqhtpuehJbTM6IYM4CkiXEyeD/GJHSlF/K3atAEefo48/QhPye+VzKwp77/7i1rw6Qpeu+Rhuf2ttF50cxOQdzkGH5s3HaPS3uVd4cRj8Yr9JPYPrXarwGSObJA9/ksjd9+Uqf2n4CmOItHccGl9sSiUbmS1RRiFrKxiDgh8QY0DbiO9m3u3B2riEcudMGfZnG7URh44RGPuJ/BM9ZTEHRbtdkOBz9JzbvMlvc/+27lYRPqxLRlo8xoB7q+jg/OqALni/MoeWeQcGOe7LCkX me@desktop"
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