# Terraform Module: aws/acm-certificate

Creates an AWS ACM certificate with domain validation and automatically creates
Route53 validation records.

```terraform
module "cert" {
  source = "github.com/halostatue/terraform-modules//aws/acm-certificate?ref=v5.x"

  providers = {
    aws.cloudfront-certificates = aws.cloudfront-certificates
    aws.route53                 = aws
  }

  domain-name  = "*.example.com"
  alternatives = {
    "example.com" = {}
    "*.example.org" = { zone-id = aws_route53_zone.example_org.zone_id }
    "example.org" = { zone-id = aws_route53_zone.example_org.zone_id }
  }
  zone-id      = aws_route53_zone.example_com.zone_id
}
```

## Input

### Providers

AWS ACM Certificates can only be created in certain regions if they are intended
for use with CloudFront, and this region may not be the same region used for
Route53 management. Therefore a `providers` alias block must be provided to the
module:

```terraform
providers = {
  aws.cloudfront-certificates = aws.cloudfront-certificates
  aws.route53                 = aws
}
```

### Required

- `domain-name`: The primary domain name for the certificate. Wildcard
  certificates may be specified.

- `zone-id`: The default Route53 zone ID for DNS validation. Used for creating
  the `domain-name` DNS validation record and for any alternative name
  validation record where `zone-id` is omitted.

### Optional

- `alternatives`: A map of domain names to objects containing an optional Route
  53 zone ID for creating validation records. If `zone-id` is omitted, falls
  back to the required `zone-id` variable value. Example:

  ```terraform
  domain-name  = "*.example.com"
  alternatives = {
    "example.com" = {}
    "*.example.org" = { zone-id = aws_route53_zone.example_org.zone_id }
    "example.org" = { zone-id = aws_route53_zone.example_org.zone_id }
  }
  zone-id      = aws_route53_zone.example_com.zone_id
  ```

  In the above example, `*.example.com` and `example.com` validation records
  will be created using `aws_route53_zone.example_com.zone_id`. `*.example.org`
  and `example.org` validation records will be created using
  `aws_route53_zone.example_org.zone_id`.

- `certificate-transparency-logging-preference`: The logging preference for
  certificate transparency. Defaults to `ENABLED`, but may be set to `DISABLED`.

- `dns-record-ttl`: Time to live for the DNS validation records. Defaults to ten
  minutes.

- `key-algorithm`: The key algorithm for this certificate. Defaults to `RSA_2048`
  (RSA 2048 bit), but supports `EC_prime256v1` (ECDSA 256 bit) and
  `EC_secp384r1` (ECDSA 384 bit). Note that CloudFront certificates _must_ be
  `RSA_2048` certificates.

- `tags`: Tags to be applied to the created certificate. The tags `Purpose`,
  `Terraform`, and `TerraformModule` will _always_ be set from the module.

## Local Variables

- `sans`: a set of local alternative names derived from `var.alternatives` key
  names.

## Output

- `id`: the ID of the ACM certificate created.

- `arn`: the ARN of the ACM certificate created.
