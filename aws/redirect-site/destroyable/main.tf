# Create a setup to redirect from an AWS S3 bucket + CloudFront distribution to
# a different distribution.
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

resource "aws_s3_bucket" "bucket" {
  bucket = local.bucket_name
  policy = jsonencode({
    Id      = "RedirectReadPolicy-${var.bucket}"
    Version = "2012-10-17"

    Statement = [
      {
        Sid = "PublicReadAccess"

        Principal = {
          AWS = "*"
        }

        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = ["arn:aws:s3:::${local.bucket_name}/*"]
      }
    ]
  })

  website {
    redirect_all_requests_to = "https://${var.target}"
  }

  tags = {
    Purpose         = "Redirect Bucket of ${var.domain} to ${var.target}"
    Terraform       = true
    TerraformModule = "github.com/halostatue/terraform-modules//aws/redirect-site@v3.0.0"
  }
}

resource "aws_iam_policy" "publisher" {
  name        = "${aws_s3_bucket.bucket.id}-publisher-policy"
  path        = "/"
  description = "Policy allowing publication of a new website version to S3."
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
    Purpose         = "Publisher Policy for redirect of ${var.domain} to ${var.target}"
    Terraform       = true
    TerraformModule = "github.com/halostatue/terraform-modules//aws/redirect-site@v3.0.0"
  }
}

resource "aws_iam_policy_attachment" "publisher" {
  name       = "${aws_s3_bucket.bucket.id}-publisher-policy-attachment"
  users      = [var.publisher]
  policy_arn = aws_iam_policy.publisher.arn
}

resource "aws_cloudfront_distribution" "redirect" {
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
      value = var.content-key
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
    Purpose         = "Cloudfront Distribution for redirect ${var.domain} to ${var.target}"
    Terraform       = true
    TerraformModule = "github.com/halostatue/terraform-modules//aws/redirect-site@v3.0.0"
  }
}
