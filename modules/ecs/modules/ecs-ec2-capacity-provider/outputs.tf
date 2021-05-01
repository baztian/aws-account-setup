output "capacity_provider_name" {
  value = aws_ecs_capacity_provider.ec2provider.name
  description = "Name of the ecs ec2 capacity provider"
}
output "capacity_provider_id" {
  value = aws_ecs_capacity_provider.ec2provider.id
  description = "Id of the ecs ec2 capacity provider"
}
output "ecs_cluster_security_group_id" {
  value = aws_security_group.ecs_cluster_sg.id
  description = "Id of the security group created for the ecs cluster"
}
output "asg_name" {
  value = module.asg.this_autoscaling_group_name
  description = "Name of the autoscaling group that got created"
}