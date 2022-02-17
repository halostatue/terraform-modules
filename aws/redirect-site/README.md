# Terraform Module: aws/redirect-site

Creates all resources for an S3-based redirect website with a CloudFront
distribution. The site is always SSL-configured, but unless a a certificate
identifier is provided, the configuration will use the default CloudFront
certificate (this is not recommended). This _depends_ on the preexistence of an
IAM user for the publisher.

This will create:

- the website redirect bucket, and
- a CloudFront distribution for the website bucket.

It is strongly recommended that the outputs from the module be raised to the
containing environment so that they are part of the shared terraform
configuration.

```terraform
module "redirect" {
  source = "github.com/halostatue/terraform-modules//aws/redirect-site?ref=v2.0"

  bucket              = "www.example.com-redirect"
  domain              = "example.com"
  target              = "www.example.com"
  publisher           = "${data.terraform_remote_state.example_com_content.publisher}"
  content-key         = "${data.terraform_remote_state.example_com_content.content-key}"
  default-ttl         = 300
  max-ttl             = 3600
  acm-certificate-arn = "arn:aws:acm:us-east-1:<account-id>:certificate/<cert-id>"
}
```

## Input

- **`domain`**: The name of the domain to provision.
- **`publisher`**: The name/ID of publisher user. This should be the output
  of an `aws/content-site` build.
- **`target`**: The destination hostname for the redirect. Do not include a
  protocol.
- **`content-key`**: The content key used to prevent duplicate content
  penalties from being applied by Google. This should be the output
  of an `aws/content-site` build.
- `bucket`: The name for the S3 bucket to create for deployment. If not
  provided, defaults to the domain name. In all cases, any period (`.`) is
  replaced with a dash (`-`).
- `content-key-base`: The base value of the content key used to prevent
  duplicate content penalties from being applied by Google. If not provided,
  defaults to the `domain` provided.
- `routing-rules`: Custom routing rules for the distribution. Must be a JSON
  document.
- `not-found-response-path`: The path to the object returned when the site
  cannot be found. Defaults to `/404.html`.
- `domain-aliases`: The optional list of aliases of the domain to provide in
  the distribution. Defaults to just the `domain` provided.
- `acm-certificate-arn`: The optional, but recommended ACM Certificate ARN.
- `default-ttl`: The default TTL for the distribution, in seconds. Defaults
  to 86,400 seconds (1 day).
- `max-ttl`: The maximum TTL for the distribution, in seconds. Defaults to
  31,536,000 seconds (365 days).

## Output

- `bucket-name`: The name of the bucket that backs the website.
- `cdn-id`: The ID of the CloudFront distribution.
- `cdn-aliases`: A comma-separated list of aliases held by the CloudFront
  distribution.
- `cdn-domain`: The name of the direct domain for the CloudFront
  distribution.
- `cdn-zone-id`: The zone where the hostname of the CloudFront distribution
  is hosted.
