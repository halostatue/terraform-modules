# Terraform Module: aws/content-site

Creates all resources for an S3-based static website with a CloudFront
distribution. The site is always SSL-configured, but unless a certificate
identifier is provided, the module will use the default CloudFront certificate
(this is not recommended as it will report an invalid certificate).

This will create:

- the website bucket,
- a logging bucket,
- a publisher user (with permissions to update the bucket and to create
  CloudFront invalidations),
- an IAM access key for the publisher, and
- a CloudFront distribution for the website bucket.

It is strongly recommended that the outputs from the module be raised to the
containing environment so that they are part of the shared terraform
configuration.

```terraform
module "content" {
  source = "github.com/halostatue/terraform-modules//aws/content-site?ref=v4.0"

  domain              = "www.example.com"
  default-ttl         = 300
  max-ttl             = 3600
  acm-certificate-arn = "arn:aws:acm:us-east-1:<account-id>:certificate/<cert-id>"
}
```

## Input

- **`domain`**: The name of the domain to provision.
- `bucket`: The name for the S3 bucket to create for deployment. If not
  provided, defaults to the domain name. In all cases, any period (`.`) is
  replaced with a dash (`-`).
- `content-key-base`: The base value of the content key used to prevent
  duplicate content penalties from being applied by Google. If not provided,
  defaults to the `domain` provided.
- `not-found-response-path`: The path to the object returned when the site
  cannot be found. Defaults to `/404.html`.
- `domain-aliases`: The optional list of aliases of the domain to provide in
  the distribution. Defaults to just the `domain` provided.
- `acm-certificate-arn`: The optional, but recommended ACM Certificate ARN. All
  CloudFront-available ARNs must be created in `us-east-1`.
- `default-ttl`: The default TTL for the distribution, in seconds. Defaults
  to 86,400 seconds (1 day).
- `max-ttl`: The maximum TTL for the distribution, in seconds. Defaults to
  31,536,000 seconds (365 days).
- `log-expiration-days`: The number of days until a log file expires.

## Output

- `bucket-name`: The name of the bucket that backs the website.
- `publisher`: The name of the publisher user.
- `publish-access-key`: The access key information, formatted so that it
  that may be placed in `~/.aws/credentials`.
- `cdn-id`: The ID of the CloudFront distribution.
- `cdn-aliases`: A comma-separated list of aliases held by the CloudFront
  distribution.
- `cdn-domain`: The name of the direct domain for the CloudFront
  distribution.
- `cdn-zone-id`: The zone where the hostname of the CloudFront distribution
  is hosted.
- `content-key`: The stable random value for the duplicate-content protection
  mechanism.
