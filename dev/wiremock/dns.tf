data "aws_route53_zone" "this" {
  name = var.hosted_zone_name
}

resource "aws_route53_record" "service" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.service_name
  type    = "A"
  alias {
    name                   = module.alb.this_lb_dns_name
    zone_id                = module.alb.this_lb_zone_id
    evaluate_target_health = true
  }
}

data "aws_acm_certificate" "issued" {
  domain   = data.aws_route53_zone.this.name
  statuses = ["ISSUED"]
}
