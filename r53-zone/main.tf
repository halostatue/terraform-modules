variable "region" { default = "" }
variable "profile" { default = "" }

variable "domain" {}

provider "aws" {
  region = "${var.region}"
  profile = "${var.profile}"
}

resource "aws_route53_zone" "zone" {
  name = "${var.domain}."
}

output "zone_id" {
  value = "${aws_route53_zone.zone.zone_id}"
}
