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
  region = "${var.region}"
  profile = "${var.profile}"
}

resource "random_id" "duplicate-content-penalty-secret" {
  keepers = {
    domain = "${coalesce("${var.random-id-domain-keeper}", "${var.domain}")}"
  }

  byte_length = 32
}

data "aws_iam_policy_document" "site-bucket-policy" {
  policy_id = "ReadPolicy-${var.bucket}"

  statement = {
    sid = "PublicReadAccess"
    principals = {
      type = "AWS"
      identifiers = [ "*" ]
    }
    effect = "Allow"
    actions = [ "s3:GetObject" ]
    resources = [ "arn:aws:s3:::${var.bucket}/*" ]
    condition = {
      test = "StringEquals"
      variable = "aws:UserAgent"
      values = [ "${random_id.duplicate-content-penalty-secret.b64}" ]
    }
  }
}

data "aws_iam_policy_document" "publisher-policy" {
  policy_id = "PublisherPolicy-${var.bucket}"

  statement = {
    sid = "PublisherListAccess"
    effect = "Allow"
    actions = [ "s3:ListBucket" ]
    resources = [ "arn:aws:s3:::${var.bucket}" ]
  }

  statement = {
    sid = "PublisherWriteAccess"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [ "arn:aws:s3:::${var.bucket}/*" ]
  }
}

resource "aws_s3_bucket" "site-log-bucket" {
  bucket = "${var.bucket}-log"
  acl = "log-delivery-write"
}

resource "aws_s3_bucket" "site-bucket" {
  bucket = "${var.bucket}"
  policy = "${data.aws_iam_policy_document.site-bucket-policy.json}"

  website {
    index_document = "index.html"
    error_document = "404.html"
    routing_rules = "${var.routing-rules}"
  }

  logging {
    target_bucket = "${aws_s3_bucket.site-log-bucket.id}"
    target_prefix = "log/"
  }

  tags {
    Name = "Bucket for static site ${var.domain}"
  }
}

resource "aws_iam_user" "publisher" {
  name = "${var.bucket}-site-publisher"
}

resource "aws_iam_access_key" "site-publisher-access-key" {
  user = "${aws_iam_user.publisher.name}"
}

resource "aws_iam_policy" "site-publisher-policy" {
  name = "site.${var.bucket}.publisher"
  path = "/"
  description = "Policy allowing publication of a new website version to S3."
  policy = "${data.aws_iam_policy_document.publisher-policy.json}"
}

resource "aws_iam_policy_attachment" "site-publisher-attach-user-policy" {
  name = "site.${var.bucket}.publisher-policy-attachment"
  users = [ "${aws_iam_user.publisher.name}" ]
  policy_arn = "${aws_iam_policy.site-publisher-policy.arn}"
}

resource "aws_cloudfront_distribution" "site-distribution" {
  enabled = true
  is_ipv6_enabled = true

  origin {
    origin_id = "${var.bucket}.origin"
    domain_name = "${aws_s3_bucket.site-bucket.website_endpoint}"

    custom_origin_config {
      origin_protocol_policy = "http-only"
      http_port = 80
      https_port = 443
      origin_ssl_protocols = [ "TLSv1", "TLSv1.1", "TLSv1.2" ]
    }

    custom_header {
      name = "User-Agent"
      value = "${random_id.duplicate-content-penalty-secret.b64}"
    }
  }

  aliases = [ "${var.domain-aliases}" ]
  default_root_object = "index.html"
  retain_on_delete = true

  custom_error_response {
    error_code = "404"
    error_caching_min_ttl = "360"
    response_code = "200"
    response_page_path = "${var.not-found-response-path}"
  }

  default_cache_behavior {
    allowed_methods = [
      "GET", "HEAD", "DELETE", "OPTIONS", "PATCH", "POST", "PUT"
    ]
    cached_methods = [ "GET", "HEAD" ]
    target_origin_id = "${var.bucket}.origin"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl = 0
    default_ttl = "${var.default-ttl}"
    max_ttl = "${var.max-ttl}"

    // This redirects any HTTP request to HTTPS. Security first!
    viewer_protocol_policy = "redirect-to-https"
    compress = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = "${length(var.acm-certificate-arn) > 0 ? "false" : "true" }"
    acm_certificate_arn = "${var.acm-certificate-arn}"
    ssl_support_method = "${length(var.acm-certificate-arn) > 0 ? "sni-only" : "" }"
    minimum_protocol_version = "TLSv1"
  }
}
