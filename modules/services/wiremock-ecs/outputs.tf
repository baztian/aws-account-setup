output "service_task_definition" {
  value = aws_ecs_service.ecs_service.task_definition
  description = "Task definition being used for the service"
}
output "image" {
  value = local.service_image
  description = "Name of the docker image being used for the service"
}
output "ssl_proxy_image" {
  value = local.ssl_proxy_image
  description = "Name of the docker image being used for the SSL reverse proxy"
}
output "image_digest" {
  value = data.docker_registry_image.service_registry_image.sha256_digest
  description = "SHA256 digest of the image being used for the service"
}
output "ssl_proxy_image_digest" {
  value = data.docker_registry_image.ssl_proxy_registry_image.sha256_digest
  description = "SHA256 digest of the image being used for the SSL reverse proxy"
}
output "log_group_name" {
  value = aws_cloudwatch_log_group.cloudwatch_log_group.name
  description = "Name of the cloudwatch log group"
}
output "wiremock_admin_password" {
  value = aws_ssm_parameter.wiremock_admin_password.value
  description = "Password for the wiremock admin user"
}