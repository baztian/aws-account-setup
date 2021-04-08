output "this_launch_configuration_id" {
  description = "The ID of the launch configuration"
  value       = module.service_asg.this_launch_configuration_id
}
output "this_autoscaling_group_id" {
  description = "The autoscaling group id"
  value       = module.service_asg.this_autoscaling_group_id
}
output "this_autoscaling_group_name" {
  value = module.service_asg.this_autoscaling_group_name
  description = "Name of the autoscaling group that got created"
}
output "this_lb_dns_name" {
  description = "DNS Name of the LB"
  value       = data.aws_lb.www_lb.dns_name
}