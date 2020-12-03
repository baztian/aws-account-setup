output "http_target_group_arn" {
  description = "The ARN of the HTTP target group"
  value = aws_lb_target_group.http_target_group.arn
}
output "alb_dns_name" {
  description = "DNS Name of the LB"
  value       = aws_lb.this_alb.dns_name
}
output "alb_http_listener_arn" {
  description = "arn of the created http alb_listeners"
  value = aws_lb_listener.http.arn
}
output "alb_https_listener_arn" {
  description = "ids of the created https alb_listeners"
  value = aws_lb_listener.https.arn
}
output "alb_security_group_id" {
  description = "id of the security associated with this ALB"
  value = module.alb_sg.this_security_group_id
}
