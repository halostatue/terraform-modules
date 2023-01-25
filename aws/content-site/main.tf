resource "random_id" "content-key" {
  keepers = {
    domain = coalesce(var.content-key-base, local.fqdn)
  }

  byte_length = 32
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

  tags = merge(local.tags, { Purpose = "content-site publisher policy for ${local.fqdn}" })
}

resource "aws_iam_group" "publishers" {
  count = local.publishers-count > 0 ? 1 : 0

  name = "${aws_s3_bucket.bucket.id}-publishers"
}

resource "aws_iam_group_membership" "publishers" {
  count = local.publishers-count > 0 ? 1 : 0

  name = "${aws_s3_bucket.bucket.id}-publishers"

  users = concat(
    tolist(var.additional-publishers),
    var.create-publisher == false ? [] : [aws_iam_user.publisher[0].name]
  )
  group = aws_iam_group.publishers[0].name
}

resource "aws_iam_group_policy_attachment" "publishers" {
  group      = aws_iam_group.publishers[0].name
  policy_arn = aws_iam_policy.publisher.arn
}

resource "aws_iam_group_policy_attachment" "additional-publisher-groups" {
  for_each = var.additional-publisher-groups

  group      = each.value
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

  tags = merge(local.tags, { Purpose = "content-site cloudfront distribution for ${local.fqdn}" })
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
