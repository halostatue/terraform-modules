resource "aws_route53_zone" "example_com" {
  name = "example.com."
}

output "zone_id" {
  value = "${aws_route53_zone.example_com.zone_id}"
}
