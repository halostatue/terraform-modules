variable "region" {
  default     = "us-east-1"
  description = "The region for the deployment bucket."
}

variable "profile" {
  description = "The AWS profile to use from the credentials file."
  default     = "default"
}

variable "bucket" {
  description = "The S3 bucket to create for deployment"
}

variable "domain" {
  description = "The name of the domain to provision."
}

provider "aws" {
  region  = "${var.region}"
  profile = "${var.profile}"
}

module "site-tfstate" {
  source = "github.com/halostatue/terraform-modules//tfstate"

  prefix = "${var.bucket}"

  # user = "${var.bucket}-terraform"
  # bucket = "${var.bucket}-tfstate"
  # tfstate-prefix = "config/"
}

module "site-zone" {
  source = "github.com/halostatue/terraform-modules//r53-zone"

  domain = "${var.domain}"
}

module "site-main" {
  source = "github.com/halostatue/terraform-modules//site-main"

  bucket                  = "${var.bucket}"
  random-id-domain-keeper = "${var.domain}"
  domain                  = "www.${var.domain}"
  domain-aliases          = ["www.${var.domain}"]
  default-ttl             = 300
  max-ttl                 = 1200

  # acm-certificate-arn = "arn:aws:acm:us-east-1:<id>:certificate/<cert-id>"
}

module "site-redirect" {
  source = "github.com/halostatue/terraform-modules//site-redirect"

  bucket                           = "${var.bucket}-redirect"
  target                           = "www.${var.domain}"
  domain-aliases                   = ["${var.domain}"]
  publisher                        = "${module.site-main.publish-user}"
  duplicate-content-penalty-secret = "${module.site-main.duplicate-content-penalty-secret}"
}

module "root-site" {
  source = "github.com/halostatue/terraform-modules//r53-cf-alias"

  zone_id            = "${module.site-zone.zone_id}"
  alias              = "${var.domain}"
  target             = "${module.site-redirect.redirect-cdn-hostname}"
  cdn_hosted_zone_id = "${module.site-redirect.redirect-cdn-zone-id}"
}

module "www-site" {
  source = "github.com/halostatue/terraform-modules//r53-cf-alias"

  zone_id            = "${module.site-zone.zone_id}"
  alias              = "www.${var.domain}"
  target             = "${module.site-main.website-cdn-hostname}"
  cdn_hosted_zone_id = "${module.site-main.website-cdn-zone-id}"
}

# module "beta-site" {
#   source = "github.com/halostatue/terraform-modules//r53-cf-alias"
#
#   zone_id = "${module.site-zone.zone_id}"
#   alias = "beta.${var.domain}"
#   target = "${module.site-main.website-cdn-hostname}"
#   cdn_hosted_zone_id = "${module.site-main.website-cdn-zone-id}"
# }

module "site-mx" {
  source = "github.com/halostatue/terraform-modules//r53-mx"

  zone_id = "${module.site-zone.zone_id}"
  ttl     = 300

  domain  = "${var.domain}"
  records = []

  # ... records ...
}

module "site-root-TXT" {
  source = "github.com/halostatue/terraform-modules//r53-txt"

  region = "${var.region}"

  zone_id = "${module.site-zone.zone_id}"
  ttl     = 300

  domain  = "${var.domain}"
  records = []

  # ... text records ...
}

module "keybase-TXT" {
  source = "github.com/halostatue/terraform-modules//r53-txt"

  zone_id = "${module.site-zone.zone_id}"
  ttl     = 300

  domain  = "_keybase.${var.domain}"
  records = []

  # ... keybase verification string ...
}

module "domainkey-TXT" {
  source = "github.com/halostatue/terraform-modules//r53-txt"

  zone_id = "${module.site-zone.zone_id}"
  ttl     = 300
  domain  = "<domainkey-prefix>._domainkey.${var.domain}"
  records = []

  # ... domainkey verification string ...
}

output "site-main.publisher" {
  value = {
    user       = "${module.site-main.publish-user}"
    access-key = "${module.site-main.publish-user-access-key}"
  }
}

output "site-main.publisher-secret-key" {
  sensitive = true
  value     = "${module.site-main.publish-user-secret-key}"
}

output "site-main.cdn" {
  value = {
    hostname = "${module.site-main.website-cdn-hostname}"
    zone_id  = "${module.site-main.website-cdn-zone-id}"
  }
}

output "site-redirect.cdn" {
  value = {
    hostname = "${module.site-redirect.redirect-cdn-hostname}"
    zone_id  = "${module.site-redirect.redirect-cdn-zone-id}"
  }
}
