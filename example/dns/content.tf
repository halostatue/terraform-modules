resource "aws_route53_record" "example_com_cf_alias_www" {
  type    = "A"
  zone_id = "${aws_route53_zone.example_com.zone_id}"
  name    = "www.example.com"

  alias {
    name    = "${data.terraform_remote_state.example_com_content.cdn-domain}"
    zone_id = "${data.terraform_remote_state.example_com_content.cdn-zone-id}"

    evaluate_target_health = false
  }
}
