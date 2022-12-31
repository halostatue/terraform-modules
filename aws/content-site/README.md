# Terraform Module: aws/content-site

Creates all resources for an S3-based static website with a CloudFront
distribution. The site is always SSL-configured, but unless a certificate
identifier is provided, the module will use the default CloudFront certificate
(this is not recommended as it will report an invalid certificate).

This will create:

- the website bucket,
- a logging bucket, and
- a CloudFront distribution for the website bucket.

Depending on configuration options, a publisher user (with a rotatable IAM
access key) may be created and a DNS record can be created.

- an optional publisher user (with permissions to update the bucket and to
  create CloudFront invalidations) with an IAM access key for the publisher, and

It is strongly recommended that the outputs from the module be raised to the
containing environment so that they are part of the shared terraform
configuration.

```terraform
module "content" {
  source = "github.com/halostatue/terraform-modules//aws/content-site?ref=v5.x"

  site-name   = "www"
  domain-name = "example.com"
  default-ttl = 300
  max-ttl     = 3600

  acm-certificate-arn = "arn:aws:acm:us-east-1:<account-id>:certificate/<cert-id>"
}
```

## Input

### Required

- `domain-name`: The base domain name for the content site bucket. Used to
  create the local `fqdn` value.

### Optional

- `site-name`: The site name for the content site bucket. Used to create the
  `fqdn` value.

- `bucket`: The name for the S3 bucket to create for deployment. If not
  provided, defaults to a transformed version of the fully-qualified domain
  name. In all cases, any period (`.`) is replaced with a dash (`-`).

- `content-key-base`: The base value of the content key used to prevent
  duplicate content penalties from being applied by Google. If not provided,
  defaults to the `domain` provided.

- `routing-rules`: A JSON-encoded array of custom routing rules for the
  distribution.

- `domain-aliases`: The optional list of aliases of the domain to provide in
  the distribution. Defaults to just the `domain` provided.

- `log-expiration-days`: The number of days until a log file expires.

- `index-document`: The S3 key for the document to return from the bucket when
  requesting an index.

- `error-document`: The S3 key for the document to return from the bucket when
  a document cannot be found. Used to specify the
  `custom_error_response.response_page_path` for the distribution.

- `acm-certificate-arn`: The optional, but recommended ACM Certificate ARN. All
  CloudFront-available ARNs must be created in `us-east-1`.

- `create-publisher`: Create a publisher user. Set to `false` to prevent
  creating a publisher user and access key.

- `publisher-name`: The name of the publisher. If not provided, defaults to
  `BUCKET-site-publisher`.

- `publisher-key-versions`: The key versions for the publisher. If omitted,
  a v1 key is created. This should be written as `[{ name = "v1", status = "Active" }]`.
  The `status` values may only be `Active` or `Inactive`.

- `additional-publishers`: Additional publisher names to which to attach the
  publisher policy.

- `dns-zone-id`: The AWS Route 53 Zone ID for creating the DNS record. If
  `dns-zone-id` or `site-name` are unspecified, a DNS record will not be
  created.

- `block-public-policy`: A boolean flag that enables or disables public policy
  blocking. Enabled by default, it may need to be disabled when public
  policies are first created or need to be updated.

- `protocol-policy`: The viewer protocol policy to use; defaults to
  `redirect-to-https`.

- `tags`: Tags to be applied to the created certificate. The tags `Purpose`,
  `Terraform`, and `TerraformModule` will _always_ be set from the module.

## Local Variables

- `fqdn`: Either `site-name.domain-name` _or_ `domain-name`, depending on
  whether `site-name` is set.

- `bucket-name`: Either `bucket` or `fqdn` with `.` replaced with `-`.

- `domain-aliases`: The unique set of values from `[fqdn, ...domain-aliases]`.

- `create-domain`: A value computed from the presence of `site-name` and
  `domain-zone-id`.

## Output

- `site`: An object with the values:

  - `bucket`: The name of the bucket.

  - `logs-bucket`: The name of the logs bucket.

  - `created-domain`: If a DNS record was created, the FQDN of the record or
    `null`.

  - `publisher`: An object with the values:

    - `created`: True if a publisher user was created.

    - `name`: The name of the created publisher user or `null`.

    - `additional-publishers`: The names of additional publisher users.

  - `cdn`: An object with the values:

    - `id`: The distribution ID.

    - `domain-name`: The name of the CloudFront distribution.

    - `zone-id`: The CloudFront zone ID.

    - `aliases`: A comma-separated list of aliases held by the CloudFront
      distribution.

- `publisher-access-keys`: A sensitive output object containing publisher IAM
  key objects with the shape:

  - _`name`_: The key name provided in `publisher-key-versions`

    - `id`: They key ID

    - `secret`: The key secret

    - `status`: The key status

- `content-key`: The random content key based on `content-key-base`.
