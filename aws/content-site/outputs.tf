output "publisher" {
  value = aws_iam_user.publisher.name
}

output "bucket-name" {
  value = aws_s3_bucket.bucket.id
}

output "publisher-access-key" {
  sensitive = true
  value     = <<CREDENTIALS

[${aws_iam_user.publisher.name}]
aws_access_key_id = ${aws_iam_access_key.publisher.id}
aws_secret_access_key = ${aws_iam_access_key.publisher.secret}

CREDENTIALS
}

output "cdn-id" {
  value = aws_cloudfront_distribution.content.id
}

output "cdn-aliases" {
  value = join(",", aws_cloudfront_distribution.content.aliases.*)
}

output "cdn-domain" {
  value = aws_cloudfront_distribution.content.domain_name
}

output "cdn-zone-id" {
  value = aws_cloudfront_distribution.content.hosted_zone_id
}

output "content-key" {
  value = random_id.content-key.b64_url
}
