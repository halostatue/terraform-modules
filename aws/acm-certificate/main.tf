locals {
  sans = toset([for key, _value in var.alternatives : key])
  sans-purpose = (
    length(var.alternatives) == 0 ? "" :
    (
      length(var.alternatives) == 1 ?
      "and one alternative name" :
      "and ${length(var.alternatives)} alternative names"
    )
  )
  tags = merge(
    var.tags,
    {
      Purpose         = "acm-certificate for ${replace(var.domain-name, "*", "WILDCARD")}${local.sans-purpose}"
      Terraform       = true
      TerraformModule = "github.com/halostatue/terraform-modules//aws/acm-certificate@v5.4.0"
    }
  )
}

resource "aws_acm_certificate" "certificate" {
  provider = aws.cloudfront-certificates

  domain_name               = var.domain-name
  validation_method         = "DNS"
  subject_alternative_names = local.sans
  key_algorithm             = var.key-algorithm

  options {
    certificate_transparency_logging_preference = var.certificate-transparency-logging-preference
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

resource "aws_route53_record" "certificate" {
  provider = aws.route53

  for_each = {
    for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone-id = coalesce(try(var.alternatives[dvo.domain_name].zone-id, null), var.zone-id)
    }
  }

  name    = each.value.name
  records = [each.value.record]
  type    = each.value.type
  zone_id = each.value.zone-id

  allow_overwrite = true
  ttl             = var.dns-record-ttl
}

resource "aws_acm_certificate_validation" "certificate" {
  provider = aws.cloudfront-certificates

  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.certificate : record.fqdn]
}
