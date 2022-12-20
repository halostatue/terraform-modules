locals {
  validation-method                           = coalesce(var.validation-method, "EMAIL")
  certificate-transparency-logging-preference = coalesce(var.certificate-transparency-logging-preference, "ENABLED")
}

resource "aws_acm_certificate" "certificate" {
  domain_name = var.domain-name

  options {
    certificate_transparency_logging_preference = local.certificate-transparency-logging-preference
  }

  subject_alternative_names = var.alternate-names
  validation_method         = local.validation-method

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Purpose         = "Certificate for ${var.domain-name}"
    Terraform       = true
    TerraformModule = "github.com/halostatue/terraform-modules//aws/create-certificate@v5.0.1"
  }
}

output "certificate-arn" {
  value = aws_acm_certificate.certificate.arn
}
