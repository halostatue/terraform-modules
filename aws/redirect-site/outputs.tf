output "bucket-name" {
  value = aws_s3_bucket.bucket.id
}

output "cdn-id" {
  value = aws_cloudfront_distribution.redirect.id
}

output "cdn-aliases" {
  value = join(",", aws_cloudfront_distribution.redirect.aliases.*)
}

output "cdn-domain" {
  value = aws_cloudfront_distribution.redirect.domain_name
}

output "cdn-zone-id" {
  value = aws_cloudfront_distribution.redirect.hosted_zone_id
}
