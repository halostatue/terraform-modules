output "site" {
  value = {
    bucket = aws_s3_bucket.bucket.id

    cdn = {
      id          = aws_cloudfront_distribution.distribution.id
      domain-name = aws_cloudfront_distribution.distribution.domain_name
      zone-id     = aws_cloudfront_distribution.distribution.hosted_zone_id
      aliases     = join(",", aws_cloudfront_distribution.distribution.aliases.*)
    }
  }
}
