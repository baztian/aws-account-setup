# Launch configuration
output "this_launch_configuration_id" {
  description = "The ID of the launch configuration"
  value       = module.service_asg.this_launch_configuration_id
}

# Autoscaling group
output "this_autoscaling_group_id" {
  description = "The autoscaling group id"
  value       = module.service_asg.this_autoscaling_group_id
}

# ALB DNS name
output "this_lb_dns_name" {
  description = "DNS Name of the LB"
  value       = data.aws_lb.www_lb.dns_name
}