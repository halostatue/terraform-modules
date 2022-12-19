# Terraform Module: aws/redirect-site

Creates all resources for an S3-based redirect website with a CloudFront
distribution. The site is always SSL-configured, but unless a certificate
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
  source = "github.com/halostatue/terraform-modules//aws/redirect-site?ref=v5.x"

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

### Required

- `target`: The destination address for the redirect, without protocol. That is,
  if redirecting to `https://www.example.com`, specify `www.example.com`.

- `domain-aliases`: The domain names that will redirect to `target`.

### Optional

- `bucket`: The name for the S3 bucket to create for deployment. If not
  provided, defaults to a transformed version of the fully-qualified domain
  name. In all cases, any period (`.`) is replaced with a dash (`-`).
- `default-ttl`: The default TTL for the distribution, in seconds. Defaults
  to 86,400 seconds (1 day).
- `max-ttl`: The maximum TTL for the distribution, in seconds. Defaults to
  31,536,000 seconds (365 days).
- `error-ttl`: The TTL for the distribution to cache error results, in seconds.
  Defaults to 1,800 seconds (30 minutes).
- `index-document`: The S3 key for the document to return from the bucket when
  requesting an index.
- `error-document`: The S3 key for the document to return from the bucket when
  a document cannot be found. Used to specify the
  `custom_error_response.response_page_path` for the distribution.
- `acm-certificate-arn`: The optional, but recommended ACM Certificate ARN. All
  CloudFront-available ARNs must be created in `us-east-1`.
- `target-protocol`: The protocol to use on redirect. If `https` (the default),
  always forces upgrade to HTTPS.
- `block-public-policy`: A boolean flag that enables or disables public policy
  blocking. Enabled by default, it may need to be disabled when public
  policies are first created or need to be updated.
- `protocol-policy`: The viewer protocol policy to use. If `target-protocol` is
  `https`, it defaults to `redirect-to-https`, otherwise it defaults to
  `allow-all`.
- `publishers`: The names or IDs of publisher users.
- `content-key`: The content key used to prevent duplicate content penalties
  from being applied by Google.

## Local Variables

- `bucket-name`: Either `bucket` or `target` with `.` replaced with `-`.
- `domain-aliases`: The unique set of values from the input `domain-aliases`.

## Output

- `site`: An object with the values:

  - `bucket`: The name of the bucket.

  - `cdn`: An object with the values:

    - `id`: The distribution ID.
    - `domain-name`: The name of the CloudFront distribution.
    - `zone-id`: The CloudFront zone ID.
    - `aliases`: A comma-separated list of aliases held by the CloudFront
      distribution.
