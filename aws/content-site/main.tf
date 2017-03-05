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

provider "aws" {
  region  = "${var.aws-region}"
  profile = "${var.aws-profile}"
}

resource "random_id" "content-key" {
  keepers = {
    domain = "${coalesce("${var.content-key-base}", "${var.domain}")}"
  }

  byte_length = 32
}

data "template_file" "bucket_name" {
  vars {
    name = "${replace(coalesce(var.bucket, var.domain), ".", "-")}"
  }

  template = "$${name}"
}

data "aws_iam_policy_document" "bucket" {
  policy_id = "AccessPolicy-${data.template_file.bucket_name.rendered}"

  statement = {
    sid = "PublicReadAccess"

    principals = {
      type        = "AWS"
      identifiers = ["*"]
    }

    effect  = "Allow"
    actions = ["s3:GetObject"]

    resources = [
      "arn:aws:s3:::${data.template_file.bucket_name.rendered}/*",
    ]

    condition = {
      test     = "StringEquals"
      variable = "aws:UserAgent"
      values   = ["${random_id.content-key.b64}"]
    }
  }
}

data "aws_iam_policy_document" "publisher" {
  policy_id = "PublisherPolicy-${aws_s3_bucket.bucket.id}"

  statement = {
    sid       = "PublisherListAccess"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["${aws_s3_bucket.bucket.arn}"]
  }

  statement = {
    sid    = "PublisherWriteAccess"
    effect = "Allow"

    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]

    resources = ["${aws_s3_bucket.bucket.arn}/*"]
  }

  statement = {
    sid       = "PublisherInvalidateAccess"
    effect    = "Allow"
    actions   = ["cloudfront:CreateInvalidation"]
    resources = ["*"]
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "${data.template_file.bucket_name.rendered}-log"
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "${data.template_file.bucket_name.rendered}"
  policy = "${data.aws_iam_policy_document.bucket.json}"

  website {
    index_document = "index.html"
    error_document = "404.html"
    routing_rules  = "${var.routing-rules}"
  }

  logging {
    target_bucket = "${aws_s3_bucket.logs.id}"
    target_prefix = "log/"
  }

  tags {
    Name      = "Bucket for static site ${var.domain}"
    Terraform = true
  }
}

resource "aws_iam_user" "publisher" {
  name = "${data.template_file.bucket_name.rendered}-publisher"
}

resource "aws_iam_access_key" "publisher" {
  user = "${aws_iam_user.publisher.name}"
}

resource "aws_iam_policy" "publisher" {
  name        = "${aws_s3_bucket.bucket.id}-publisher-policy"
  path        = "/"
  description = "Policy allowing publication of a new website version for ${var.domain} to S3."
  policy      = "${data.aws_iam_policy_document.publisher.json}"
}

resource "aws_iam_policy_attachment" "publisher" {
  name       = "${aws_s3_bucket.bucket.id}-publisher-policy-attachment"
  users      = ["${aws_iam_user.publisher.name}"]
  policy_arn = "${aws_iam_policy.publisher.arn}"
}

resource "aws_cloudfront_distribution" "content" {
  enabled         = true
  is_ipv6_enabled = true

  origin {
    origin_id   = "${aws_s3_bucket.bucket.id}.origin"
    domain_name = "${aws_s3_bucket.bucket.website_endpoint}"

    custom_origin_config {
      origin_protocol_policy = "http-only"
      http_port              = 80
      https_port             = 443
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    custom_header {
      name  = "User-Agent"
      value = "${random_id.content-key.b64}"
    }
  }

  aliases = [
    "${distinct(compact(concat(list("${var.domain}"), "${var.domain-aliases}")))}",
  ]

  default_root_object = "index.html"
  retain_on_delete    = true

  custom_error_response {
    error_code            = "404"
    error_caching_min_ttl = "360"
    response_code         = "200"
    response_page_path    = "${var.not-found-response-path}"
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
    default_ttl = "${var.default-ttl}"
    max_ttl     = "${var.max-ttl}"

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
    cloudfront_default_certificate = "${length(var.acm-certificate-arn) > 0 ? "false" : "true" }"
    acm_certificate_arn            = "${var.acm-certificate-arn}"
    ssl_support_method             = "${length(var.acm-certificate-arn) > 0 ? "sni-only" : "" }"
    minimum_protocol_version       = "TLSv1"
  }
}
