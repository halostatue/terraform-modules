variable "region" { default = "" }
variable "profile" { default = "" }

variable "cdn_hosted_zone_id" {}
variable "target" {}
variable "zone_id" {}
variable "alias" {}

provider "aws" {
  region = "${var.region}"
  profile = "${var.profile}"
}

resource "aws_route53_record" "cf-alias" {
  zone_id = "${var.zone_id}"
  name = "${var.alias}"
  type = "A"

  alias {
    name = "${var.target}"
    zone_id = "${var.cdn_hosted_zone_id}"
    evaluate_target_health = false
  }
}
