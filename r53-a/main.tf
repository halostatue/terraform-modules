variable "region" { default = "" }
variable "profile" { default = "" }
variable "ttl" { default = 86400 }

variable "domain" {}
variable "zone_id" {}
variable "records" { type = "list" }

provider "aws" {
  region = "${var.region}"
  profile = "${var.profile}"
}

resource "aws_route53_record" "a" {
  zone_id = "${var.zone_id}"
  name = "${var.domain}"
  type = "A"
  ttl = "${var.ttl}"
  records = [ "${var.records}" ]
}
