output "ecs_cluster_id" {
    value = module.ecs.this_ecs_cluster_id
    description = "Id of the ecs cluster created by this module"
}
output "ecs_cluster_name" {
    value = module.ecs.this_ecs_cluster_name
    description = "Name of the ecs cluster created by this module"
}
