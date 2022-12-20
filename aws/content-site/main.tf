locals {
  fqdn           = join(".", compact([var.site-name, var.domain-name]))
  bucket-name    = replace(coalesce(var.bucket, local.fqdn), ".", "-")
  domain-aliases = distinct(compact(flatten(concat([local.fqdn], var.domain-aliases))))
  create-domain = (
    (
      var.dns-zone-id == null || var.site-name == null
    ) ? 0 : (length(var.dns-zone-id) > 0 && length(var.site-name) > 0) ? 1 : 0
  )
}

resource "random_id" "content-key" {
  keepers = {
    domain = coalesce(var.content-key-base, local.fqdn)
  }

  byte_length = 32
}

resource "aws_s3_bucket" "logs" {
  bucket = "${local.bucket-name}-log"

  tags = {
    Purpose         = "Log bucket for static site ${local.fqdn}"
    Terraform       = true
    TerraformModule = "github.com/halostatue/terraform-modules//aws/content-site@v5.0.1"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    id     = "log-expiration"
    status = "Enabled"

    expiration {
      days = var.log-expiration-days
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = local.bucket-name

  tags = {
    Purpose         = "Bucket for static site ${local.fqdn}"
    Terraform       = true
    TerraformModule = "github.com/halostatue/terraform-modules//aws/content-site@v5.0.1"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_logging" "bucket" {
  bucket        = aws_s3_bucket.bucket.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "log/"
}

resource "aws_s3_bucket_policy" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  policy = jsonencode({
    Id      = "AccessPolicy-${local.bucket-name}"
    Version = "2012-10-17"

    Statement = [
      {
        Sid = "PublicReadAccess"
        Principal = {
          AWS = "*"
        }

        Effect = "Allow"
        Action = ["s3:GetObject"]

        Resource = ["arn:aws:s3:::${local.bucket-name}/*"]

        Condition = {
          StringEquals = {
            "aws:UserAgent" = random_id.content-key.b64_url
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_ownership_controls" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = var.block-public-policy
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_website_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  index_document {
    suffix = var.index-document
  }

  error_document {
    key = var.error-document
  }

  routing_rules = var.routing-rules
}

resource "aws_iam_user" "publisher" {
  count = var.create-publisher == false ? 0 : 1

  name = coalesce(var.publisher-name, "${local.bucket-name}-publisher")

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Purpose         = "Publishing user for ${local.fqdn}"
    Terraform       = true
    TerraformModule = "github.com/halostatue/terraform-modules//aws/content-site@v5.0.1"
  }
}

locals {
  publisher_key_versions = var.create-publisher == false ? {} : (
    var.publisher-key-versions == null ? { "v1" = "Active" } :
    merge([for kv in var.publisher-key-versions : { (kv.name) = kv.status }]...)
  )
}

resource "aws_iam_access_key" "publisher-access-key" {
  for_each = local.publisher_key_versions

  user   = aws_iam_user.publisher[0].id
  status = each.value

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_policy" "publisher" {
  name        = "${aws_s3_bucket.bucket.id}-publisher-policy"
  path        = "/"
  description = "Policy allowing publication of a new website version for ${local.fqdn} to S3."

  policy = jsonencode({
    Id      = "PublisherPolicy-${aws_s3_bucket.bucket.id}"
    Version = "2012-10-17"

    Statement = [
      {
        Sid      = "PublisherListAccess"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [aws_s3_bucket.bucket.arn]
      },
      {
        Sid    = "PublisherWriteAccess"
        Effect = "Allow"
        Action = [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
        ]
        Resource = ["${aws_s3_bucket.bucket.arn}/*"]
      },
      {
        Sid      = "PublisherInvalidateAccess"
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation"]
        Resource = ["*"]
      }
    ]
  })

  tags = {
    Purpose         = "Publishing user policy for ${local.fqdn}"
    Terraform       = true
    TerraformModule = "github.com/halostatue/terraform-modules//aws/content-site@v5.0.1"
  }
}

resource "aws_iam_policy_attachment" "publisher" {
  count = var.create-publisher == false ? 0 : 1

  name       = "${aws_s3_bucket.bucket.id}-publisher-policy-attachment"
  users      = [aws_iam_user.publisher[0].name]
  policy_arn = aws_iam_policy.publisher.arn
}

resource "aws_iam_group" "additional-publishers" {
  count = length(var.additional-publishers) == 0 ? 0 : 1
  name  = "${aws_s3_bucket.bucket.id}-additional-publishers"
}

resource "aws_iam_group_membership" "additional-publishers" {
  count = length(var.additional-publishers) == 0 ? 0 : 1

  name = "${aws_s3_bucket.bucket.id}-additional-publishers"

  users = var.additional-publishers
  group = aws_iam_group.additional-publishers[0].name
}

resource "aws_iam_group_policy_attachment" "additional-publishers" {
  count = length(var.additional-publishers) == 0 ? 0 : 1

  group      = aws_iam_group.additional-publishers[0].name
  policy_arn = aws_iam_policy.publisher.arn
}

resource "aws_cloudfront_distribution" "distribution" {
  enabled         = true
  is_ipv6_enabled = true

  origin {
    origin_id   = "${aws_s3_bucket.bucket.id}.origin"
    domain_name = aws_s3_bucket_website_configuration.bucket.website_endpoint

    custom_origin_config {
      origin_protocol_policy = "http-only"
      http_port              = 80
      https_port             = 443
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    custom_header {
      name  = "User-Agent"
      value = random_id.content-key.b64_url
    }
  }

  aliases = local.domain-aliases

  default_root_object = var.index-document
  retain_on_delete    = true

  custom_error_response {
    error_code            = "404"
    error_caching_min_ttl = var.error-ttl
    response_code         = "200"
    response_page_path    = "/${var.error-document}"
  }

  default_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
      "DELETE",
      "OPTIONS",
      "PATCH",
      "POST",
      "PUT",
    ]

    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${aws_s3_bucket.bucket.id}.origin"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = var.default-ttl
    max_ttl     = var.max-ttl
    compress    = true

    viewer_protocol_policy = var.protocol-policy
  }

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = length(var.acm-certificate-arn) > 0 ? false : true
    acm_certificate_arn            = var.acm-certificate-arn
    ssl_support_method             = length(var.acm-certificate-arn) > 0 ? "sni-only" : ""
    minimum_protocol_version       = "TLSv1"
  }

  tags = {
    Purpose         = "Cloudfront distribution for ${local.fqdn}"
    Terraform       = true
    TerraformModule = "github.com/halostatue/terraform-modules//aws/content-site@v5.0.1"
  }
}

resource "aws_route53_record" "dns-record" {
  count = local.create-domain

  zone_id = var.dns-zone-id
  name    = var.site-name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.distribution.domain_name
    zone_id                = aws_cloudfront_distribution.distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
