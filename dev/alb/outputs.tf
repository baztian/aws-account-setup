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
