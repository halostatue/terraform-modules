output "site" {
  value = {
    bucket = aws_s3_bucket.bucket.id

    logs-bucket = aws_s3_bucket.logs.id

    created-domain = local.create-domain > 1 ? aws_route53_record.dns-record[0].fqdn : null

    publisher = {
      created               = var.create-publisher
      name                  = var.create-publisher == false ? null : aws_iam_user.publisher[0].name
      additional-publishers = var.additional-publishers
    }

    cdn = {
      id          = aws_cloudfront_distribution.distribution.id
      domain-name = aws_cloudfront_distribution.distribution.domain_name
      zone-id     = aws_cloudfront_distribution.distribution.hosted_zone_id
      aliases     = join(",", aws_cloudfront_distribution.distribution.aliases.*)
    }
  }
}

output "publisher-access-keys" {
  sensitive = true
  value = var.create-publisher == false ? {} : merge([
    for name, key in aws_iam_access_key.publisher-access-key : {
      (name) = {
        id     = key.id
        secret = key.secret
        status = key.status
      }
  }]...)
}

output "content-key" {
  sensitive = true
  value     = random_id.content-key.b64_url
}
