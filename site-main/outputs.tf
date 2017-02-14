output "publish-user" {
  value = "${aws_iam_user.publisher.name}"
}

output "publish-user-access-key" {
  value = "${aws_iam_access_key.site-publisher-access-key.id}"
}

output "publish-user-secret-key" {
  value = "${aws_iam_access_key.site-publisher-access-key.secret}"
}

output "website-cdn-hostname" {
  value = "${aws_cloudfront_distribution.site-distribution.domain_name}"
}

output "website-cdn-zone-id" {
  value = "${aws_cloudfront_distribution.site-distribution.hosted_zone_id}"
}

output "duplicate-content-penalty-secret" {
  value = "${random_id.duplicate-content-penalty-secret.b64}"
}
