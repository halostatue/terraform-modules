output "bucket-name" {
  value = "${data.template_file.bucket_name.rendered}"
}

output "cdn-id" {
  value = "${aws_cloudfront_distribution.redirect.id}"
}

output "cdn-aliases" {
  # value = "${join(",", distinct(compact(concat(list(var.domain), var.domain-aliases))))}"
  value = "${join(",", aws_cloudfront_distribution.redirect.alias.*)}"
}

output "cdn-domain" {
  value = "${aws_cloudfront_distribution.redirect.domain_name}"
}

output "cdn-zone-id" {
  value = "${aws_cloudfront_distribution.redirect.hosted_zone_id}"
}
