output "service_task_definition" {
  value = module.wiremock-ecs.service_task_definition
  description = "Task definition being used for the service"
}
output "image" {
  value = module.wiremock-ecs.image
  description = "Name of the docker image being used for the service"
}
output "image_digest" {
  value = module.wiremock-ecs.image_digest
  description = "SHA256 digest of the image being used for the service"
}
