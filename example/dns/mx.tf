resource "aws_route53_record" "example_com_mx" {
  type    = "MX"
  zone_id = "${aws_route53_zone.example_com.zone_id}"

  name = "example.com"

  records = [
    "10 aspmx.l.google.com.",
    "20 alt2.aspmx.l.google.com.",
    "20 alt1.aspmx.l.google.com.",
    "30 aspmx3.googlemail.com.",
    "30 aspmx2.googlemail.com.",
  ]

  ttl = "${var.ttl}"
}
