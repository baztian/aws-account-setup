data "aws_route53_zone" "this" {
  name = var.hosted_zone_name
}

resource "aws_route53_record" "service" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "*"
  type    = "A"
  alias {
    name                   = aws_lb.this_alb.dns_name
    zone_id                = aws_lb.this_alb.zone_id
    evaluate_target_health = true
  }
}

data "aws_acm_certificate" "issued" {
  domain   = data.aws_route53_zone.this.name
  statuses = ["ISSUED"]
}
