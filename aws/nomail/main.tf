// Based on https://www.gov.uk/guidance/protect-domains-that-dont-send-email

resource "aws_route53_record" "spf_txt" {
  count = var.include-spf ? 1 : 0

  type    = "TXT"
  zone_id = var.zone-id

  name    = var.name
  records = ["v=spf1 -all"]

  ttl = var.ttl
}

locals {
  dmarc-sp     = var.subdomains-send-email ? "none" : "reject"
  dmarc-rua    = length(var.dmarc-rua) > 0 ? ";rua=${join(",", var.dmarc-rua)}" : ""
  dmarc-ruf    = length(var.dmarc-ruf) > 0 ? ";ruf=${join(",", var.dmarc-ruf)}" : ""
  dmarc-record = "v=DMARC1;p=reject;sp=${local.dmarc-sp};adkim=s;aspf=s;fo=1${local.dmarc-rua}${local.dmarc-ruf}"
}

resource "aws_route53_record" "dmarc" {
  type    = "TXT"
  zone_id = var.zone-id

  name    = "_dmarc.${var.name}"
  records = [local.dmarc-record]

  ttl = var.ttl
}

resource "aws_route53_record" "dkim" {
  type    = "TXT"
  zone_id = var.zone-id

  name    = var.is-subdomain ? "_domainkey.${var.name}" : "*._domainkey.${var.name}"
  records = ["v=DKIM1;p="]

  ttl = var.ttl
}
