resource "aws_route53_record" "example_com_cf_alias" {
  type    = "A"
  zone_id = "${aws_route53_zone.example_com.zone_id}"
  name    = "example.com"

  alias {
    name    = "${data.terraform_remote_state.example_com_redirect.cdn-domain}"
    zone_id = "${data.terraform_remote_state.example_com_redirect.cdn-zone-id}"

    evaluate_target_health = false
  }
}
