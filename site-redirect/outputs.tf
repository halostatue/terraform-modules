output "redirect-cdn-hostname" {
  value = "${aws_cloudfront_distribution.redirect-distribution.domain_name}"
}

output "redirect-cdn-zone-id" {
  value = "${aws_cloudfront_distribution.redirect-distribution.hosted_zone_id}"
}
