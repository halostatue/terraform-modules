# Create a setup to serve a static website from an AWS S3 bucket, with a
# Cloudfront CDN and certificates from AWS Certificate Manager.
#
# Bucket name restrictions:
#    http://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html
#
# Duplicate Content Penalty protection:
#    Description: https://support.google.com/webmasters/answer/66359?hl=en
#    Solution: http://tuts.emrealadag.com/post/cloudfront-cdn-for-s3-static-web-hosting/
#        Section: Restricting S3 access to Cloudfront
#
# Deploy remark:
#    Do not push files to the S3 bucket with an ACL giving public READ access,
#    e.g s3-sync --acl-public
#
# 2016-05-16
#    AWS Certificate Manager supports multiple regions. To use CloudFront with
#    ACM certificates, the certificates must be requested in region us-east-1

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

locals {
  bucket_name = replace(coalesce(var.bucket, var.domain), ".", "-")
}

resource "random_id" "content-key" {
  keepers = {
    domain = coalesce(var.content-key-base, var.domain)
  }

  byte_length = 32
}

resource "aws_s3_bucket" "logs" {
  bucket = "${local.bucket_name}-log"
  acl    = "log-delivery-write"

  lifecycle_rule {
    id      = "tfstate"
    prefix  = ""
    enabled = true

    expiration {
      days = var.log-expiration-days
    }
  }

  tags = {
    Purpose         = "Log bucket for static site ${var.domain}"
    Terraform       = true
    TerraformModule = "github.com/halostatue/terraform-modules//aws/content-site@v3.1.1"
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = local.bucket_name
  policy = jsonencode({
    Id      = "AccessPolicy-${local.bucket_name}"
    Version = "2012-10-17"

    Statement = [
      {
        Sid       = "PublicReadAccess"
        Principal = "*"

        Effect = "Allow"
        Action = ["s3:GetObject"]

        Resource = ["arn:aws:s3:::${local.bucket_name}/*"]

        Condition = {
          StringEquals = {
            "aws:UserAgent" = random_id.content-key.b64_url
          }
        }
      }
    ]
  })

  website {
    index_document = "index.html"
    error_document = "404.html"
    routing_rules  = var.routing-rules
  }

  logging {
    target_bucket = aws_s3_bucket.logs.id
    target_prefix = "log/"
  }

  tags = {
    Purpose         = "Bucket for static site ${var.domain}"
    Terraform       = true
    TerraformModule = "github.com/halostatue/terraform-modules//aws/content-site@v3.1.1"
  }
}

resource "aws_iam_user" "publisher" {
  name = "${local.bucket_name}-publisher"

  tags = {
    Purpose         = "Publishing user for ${var.domain}"
    Terraform       = true
    TerraformModule = "github.com/halostatue/terraform-modules//aws/content-site@v3.1.1"
  }
}

resource "aws_iam_access_key" "publisher" {
  user = aws_iam_user.publisher.name
}

resource "aws_iam_policy" "publisher" {
  name        = "${aws_s3_bucket.bucket.id}-publisher-policy"
  path        = "/"
  description = "Policy allowing publication of a new website version for ${var.domain} to S3."
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
          "s3:GetObjectAcl",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:PutObjectAcl",
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
    Purpose         = "Publishing user policy for ${var.domain}"
    Terraform       = true
    TerraformModule = "github.com/halostatue/terraform-modules//aws/content-site@v3.1.1"
  }
}

resource "aws_iam_policy_attachment" "publisher" {
  name       = "${aws_s3_bucket.bucket.id}-publisher-policy-attachment"
  users      = [aws_iam_user.publisher.name]
  policy_arn = aws_iam_policy.publisher.arn
}

resource "aws_cloudfront_distribution" "content" {
  enabled         = true
  is_ipv6_enabled = true

  origin {
    origin_id   = "${aws_s3_bucket.bucket.id}.origin"
    domain_name = aws_s3_bucket.bucket.website_endpoint

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

  aliases = distinct(compact(flatten(concat([var.domain], var.domain-aliases))))

  default_root_object = "index.html"
  retain_on_delete    = true

  custom_error_response {
    error_code            = "404"
    error_caching_min_ttl = "360"
    response_code         = "200"
    response_page_path    = var.not-found-response-path
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

    // This redirects any HTTP request to HTTPS. Security first!
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = length(var.acm-certificate-arn) > 0 ? "false" : "true"
    acm_certificate_arn            = var.acm-certificate-arn
    ssl_support_method             = length(var.acm-certificate-arn) > 0 ? "sni-only" : ""
    minimum_protocol_version       = "TLSv1"
  }

  tags = {
    Purpose         = "Cloudfront distribution for ${var.domain}"
    Terraform       = true
    TerraformModule = "github.com/halostatue/terraform-modules//aws/content-site@v3.1.1"
  }
}
