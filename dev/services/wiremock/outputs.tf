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
output "wiremock_admin_password" {
  value = module.wiremock-ecs.wiremock_admin_password
  description = "Password for the wiremock admin user"
}