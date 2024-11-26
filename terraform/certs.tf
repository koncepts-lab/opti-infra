resource "aws_route53_zone" "oi_portal" {
  name = "oi-portal.com"
}

import {
  to = aws_route53_zone.oi_portal
  id = "Z07252743MSRHEC3NJWG"
}

resource "aws_acm_certificate" "oi_portal_region_local" {
  domain_name               = "oi-portal.com"
  subject_alternative_names = ["*.oi-portal.com"]
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${local.prefix}-oi_portal_region_local_cert"
  }

}
resource "aws_route53_record" "validation" {
  zone_id = aws_route53_zone.oi_portal.zone_id
  name    = tolist(aws_acm_certificate.oi_portal_region_local.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.oi_portal_region_local.domain_validation_options)[0].resource_record_type
  records = [tolist(aws_acm_certificate.oi_portal_region_local.domain_validation_options)[0].resource_record_value]
  ttl     = "300"
}

resource "aws_acm_certificate_validation" "oi_portal_region_local" {
  certificate_arn         = aws_acm_certificate.oi_portal_region_local.arn
  validation_record_fqdns = [aws_route53_record.validation.fqdn]
}
