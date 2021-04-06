output "service_task_definition" {
  value = aws_ecs_service.wiremock.task_definition
  description = "Task definition being used for the service"
}
output "image" {
  value = local.image
  description = "Name of the docker image being used for the service"
}
output "image_digest" {
  value = data.docker_registry_image.wiremock.sha256_digest
  description = "SHA256 digest of the image being used for the service"
}