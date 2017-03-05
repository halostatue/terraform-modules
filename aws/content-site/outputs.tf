output "publisher" {
  value = "${aws_iam_user.publisher.name}"
}

data "template_file" "publisher_access_key" {
  vars {
    name   = "${aws_iam_user.publisher.name}"
    id     = "${aws_iam_access_key.publisher.id}"
    secret = "${aws_iam_access_key.publisher.secret}"
  }

  template = <<EOF

[$${name}]
aws_access_key_id = $${id}
aws_secret_access_key = $${secret}

EOF
}

output "bucket-name" {
  value = "${data.template_file.bucket_name.rendered}"
}

output "publisher-access-key" {
  sensitive = true
  value     = "${data.template_file.publisher_access_key.rendered}"
}

output "cdn-id" {
  value = "${aws_cloudfront_distribution.content.id}"
}

output "cdn-aliases" {
  # value = "${join(",", distinct(compact(concat(list(var.domain), var.domain-aliases))))}"
  value = "${join(",", aws_cloudfront_distribution.content.alias.*)}"
}

output "cdn-domain" {
  value = "${aws_cloudfront_distribution.content.domain_name}"
}

output "cdn-zone-id" {
  value = "${aws_cloudfront_distribution.content.hosted_zone_id}"
}

output "content-key" {
  value = "${random_id.content-key.b64}"
}
