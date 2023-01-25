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
            "aws:UserAgent" = var.content-key
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

  redirect_all_requests_to {
    protocol  = var.target-protocol
    host_name = var.target
  }
}

resource "aws_iam_policy" "publisher" {
  path        = "/"
  description = "Policy allowing publication for redirects for ${var.target} from S3."

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

  tags = merge(local.tags, { Purpose = "redirect-site publisher policy for redirects to ${var.target}" })
}

resource "aws_iam_group" "publishers" {
  count = length(var.publishers) > 0 ? 1 : 0
  name  = "${aws_s3_bucket.bucket.id}-publishers"
}

resource "aws_iam_group_membership" "publishers" {
  count = length(var.publishers) == 0 ? 0 : 1

  name = "${aws_s3_bucket.bucket.id}-publishers"

  users = var.publishers
  group = aws_iam_group.publishers[0].name
}

resource "aws_iam_group_policy_attachment" "publishers" {
  count = length(var.publishers) == 0 ? 0 : 1

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
      value = var.content-key
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

    viewer_protocol_policy = var.target-protocol == "https" ? "redirect-to-https" : var.protocol-policy
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

  tags = merge(
    local.tags,
    {
      Purpose         = "redirect-site cloudfront distribution for redirects to ${var.target}"
      Terraform       = true
      TerraformModule = "github.com/halostatue/terraform-modules//aws/redirect-site@v5.2.0"
  })
}
