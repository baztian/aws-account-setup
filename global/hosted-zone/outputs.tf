# Domain validation records
output "this_acm_domain_validation_options" {
  description = "Domain validation options to be used for the domain's CNAME records"
  value       = aws_acm_certificate.my_certificate_request.domain_validation_options
}
output "this_acm_certificate_arn" {
  description = "ARN of the certificate"
  value       = aws_acm_certificate.my_certificate_request.arn
}
output "this_route53_name_servers" {
  description = "A list of name servers that are associated to the hosted zone"
  value       = aws_route53_zone.my_hosted_zone.name_servers
}
