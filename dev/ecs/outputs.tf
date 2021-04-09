output "ecs_cluster_id" {
    value = module.ecs.ecs_cluster_id
    description = "Id of the ecs cluster created by this module"
}
output "ecs_cluster_name" {
    value = module.ecs.ecs_cluster_name
    description = "Name of the ecs cluster created by this module"
}
output "ecs_cluster_security_group_id" {
    value = module.ecs.ecs_cluster_security_group_id
    description = "Id of the security group created for the ecs cluster"
}
output "asg_name" {
    value = module.ecs.asg_name
    description = "Name of the autoscaling group that got created"
}