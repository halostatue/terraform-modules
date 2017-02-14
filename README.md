# Terraform-Modules

This repository contains the [Terraform][] modules required to setup a static
website, hosted out of an S3 bucket. The site is fronted by a CloudFront
distribution, can use AWS Certificate Manager for HTTPS and allows for
configuring the required DNS entries in Route53. Let’s Encrypt support (through
AWS Lambda) is being explored.
 
The modules also take care of:

*   preventing the origin bucket being indexed by search bots (avoiding the
    Google [duplicate content penalty][]);
*   redirect other domains to the main site with proper rewriting;
*   access logging; and
*   redirecting HTTP to HTTPS.

These modules are derived from [scripts][] by [Ringo De Smet][].

## Introduction

There are multiple modules provided in this repository, generally based around
my needs, but also to work around the lack of conditional logic in Terraform.
Some of these are extremely simple wrappers around normal resources, but exist
to provide common inherited integration (especially around the aliased AWS
provider).

*   *tfstate*: Create and manage a bucket to store Terraform state remotely.
*   *r53-zone*: Configuration of a Route53 Zone.
*   *r53-a*: Configuration of a Route53 A (non-ALIAS) record.
*   *r53-mx*: Configuration of a Route53 MX record.
*   *r53-txt*: Configuration of a Route53 TXT record.
*   *r53-cname*: Configuration of a Route53 ALIAS record.
*   *r53-cf-alias*: Configuration of an ALIAS Route53 A record pointing to a
    CloudFront distribution. Required for naked domain (apex) setups.
*   *site-main*: Create and configure the main S3 bucket with CloudFront
    distribution.
*   *site-redirect*: Create and configure a redirect S3 bucket with CloudFront
    distribution.

Using these modules, you can compose everything you need to make various types
of configurations.

*   Create a single site on a subdomain (https://www.example.com/).
*   Create a single site on an apex domain (https://example.com/).
*   Create the main site on a subdomain (https://www.example.com/) and
    redirecting the naked domain (https://example.com/) to the subdomain.
*   Create the main site on an apex domain (https://example.com/) and
    redirecting the subdomain (https://www.example.com/) to the apex domain.

These modules do not support creating non-SSL sites, but they are configurable
to either use the default CloudFront certificate (which will result in identity
warnings) or an AWS Certificate Manager-based certificate (which must be
configured manually prior to using these scripts). Support for Let's Encrypt
certificates is being explored.

> __Note__: AWS Certificate Manager supports multiple regions, but CloundFront
> appears to have a restriction that those certificates must be requested in
> us-east-1.

## Configuring Terraform

These modules are known to work with Terraform `0.8.x` and may not work a later
version.

### Provider Configuration

To simplify configuration, all of the modules expect the primary module to be
configured to use a named profile in the AWS credentials file
(`${HOME}/.aws/credentials`), as well as be configured for the appropriate
region. The region and profile may be overridden by specifying `region` and
`profile` inputs to the modules.

```terraform
variable "region" {
  default = "us-east-1"
  description = "The region for the deployment bucket."
}
variable "profile" {
  description = "The AWS profile to use from the credentials file."
  default = "default"
}

provider "aws" {
  region = "${var.region}"
  profile = "${var.profile}"
}

module "site-zone" { # Uses the default provider.
  source = "github.com/halostatue/terraform-modules//r53-zone"

  # ...
}

module "site-tfstate" { # Uses a different provider.
  source = "github.com/halostatue/terraform-modules//tfstate"

  region = "us-west-1"
  profile = "terraform-state"

  # ...
}
```

### Module Source Selection

As noted in the Terraform [Modules documentation][], GitHub is treated as a
special source for modules. Each of the modules can be reached with the
appropriate source specification.

```terraform
module "site-tfstate" {
  source = "github.com/halostatue/terraform-modules//tfstate"
  # ...
}
```

## Provided Modules

If an input name is __`bold`__, it is required. Otherwise, it is optional.

### tfstate

Configures an S3 bucket (with versioning and a 90 day lifecycle policy) and
user (with policy) to store the Terraform state remotely. It is recommended
that the user created for working with Terraform be imported once this module
is present, but before application.

```terraform
module "site-tfstate" {
  source = "github.com/halostatue/terraform-modules//tfstate"

  prefix = "${var.bucket}"
}
```

Once created, terraform must be configured with the appropriate output. This
can be retrieved with `terraform output` for the module.

```sh
terraform output -module=site-tfstate
```

#### Input

The `region` and `profile` inputs affect the AWS provider in the module.

*   `tfstate-prefix` (default `config/`): The prefix (directory) to use for
    storing the Terraform state (___`tfstate-prefix`___`/terraform.tfstate`,
    where the default is `config/terraform.tfstate`).
*   `prefix`: The prefix for the bucket name and/or the user. Optional, these
    items may be specified explicitly.
*   `user`: The user to be created. Optional, defaults to
    ___`prefix`___`-terraform`.
*   `bucket`: The bucket to be created. Optional, defaults to
    ___`prefix`___`-tfstate`.

> __Note__: If none of `prefix`, `user`, or `bucket` are specified, the user
> will be `-terraform` and the bucket will be `-tfstate`. This is probably not
> what you want, so either `prefix` should be supplied or `user` and `bucket`
> should be supplied.

#### Output

*   `terraform-config-command`: The `terraform remote config` command to use
    with the bucket provided.

### r53-zone

Configures the Route53 zone.

```terraform
module "site-zone" {
  source = "github.com/halostatue/terraform-modules//r53-zone"
  domain = "example.com"
}
```

#### Input

The `region` and `profile` inputs affect the AWS provider in the module.

*   __`domain`__: This will create the appropriate zone using this name. Use
    `terraform import` to handle an already existing zone.

    ```sh
    terraform import \
      module.site-zone.aws_route53_zone.zone \
      DECAFBAD_example.com
    ```

#### Ouptut

*   `zone_id`: Returns the zone ID for the managed Route53 zone. Access through
    `${module.NAME.zone_id}` (e.g., `${module.site-zone.zone_id}`).

### r53-a, r53-mx, r53-txt, r53-cname

Configures a Route53 A, MX, or TXT record for the specified zone. When creating
an A record, note that this cannot be used for CloudFront; use `r53-cf-alias`
instead.

```terraform
module "site-a" {
  source = "github.com/halostatue/terraform-modules//r53-a"

  zone_id = "${module.site-zone.zone_id}"
  domain = "dns.example.com"
  records = [ 8.8.8.8 ]
}

module "site-mx" {
  source = "github.com/halostatue/terraform-modules//r53-mx"

  zone_id = "${module.site-zone.zone_id}"
  domain = "example.com"
  records = [
    "10 ASPMX.L.GOOGLE.COM.",
    "20 ALT2.ASPMX.L.GOOGLE.COM.",
    "20 ALT1.ASPMX.L.GOOGLE.COM.",
    "30 ASPMX3.GOOGLEMAIL.COM.",
    "30 ASPMX2.GOOGLEMAIL.COM."
  ]
}

module "site-txt" {
  source = "github.com/halostatue/terraform-modules//r53-txt"

  zone_id = "${module.site-zone.zone_id}"
  domain = "example.com"
  records = [
    "google-site-verification=gibberish"
  ]
}

module "site-cname" {
  source = "github.com/halostatue-terraform-modules//r53-cname"

  zone_id = "${module.site-zone.zone_id}"
  domain = "pages.example.com"
  records = [
    "example.github.io"
  ]
}
```

#### Input

The `region` and `profile` inputs affect the AWS provider in the module.

*   __`domain`__: This will create the record for this name.
*   __`zone_id`__: The Zone in which to create the record.
*   __`records`__: The records which will be added as a possible
    resolution to this record.
*   `ttl` (default `86400`): The TTL for this record.

### r53-cf-alias

Configures a Route53 A record as an ALIAS to a CloudFront distribution.

```terraform
module "site-alias" {
  source = "github.com/halostatue/terraform-modules//r53-cf-alias"

  zone_id = "${module.site-zone.zone_id}"
  alias = "example.com"
  cdn_hosted_zone_id = "${module.site-redirect.redirect-cdn-hostname}"
  target = "${module.site-redirect.redirect-cdn-hostname}"
}

```

#### Input

The `region` and `profile` inputs affect the AWS provider in the module.

*   __`alias`__: This will create the record for this name.
*   __`zone_id`__: The Zone in which to create the record.
*   __`cdn_hosted_zone_id`__: The CloudFront hosted zone.
*   __`target`__: The CloudFront hostname to use as the target.

### site-main

Creates all resources for an S3-based static website with a CloudFront
distribution. The site is always SSL-configured, but unless a a certificate
identifier is provided, the configuration will use the default CloudFront
certificate (this is not recommended). Let's Encrypt support is being explored.

This will create:

*   the website bucket,
*   a logging bucket,
*   a publisher user,
*   an IAM access key for the publisher, and
*   a CloudFront distribution for the website bucket.

```terraform
module "site-main" {
  source = "github.com/halostatue/terraform-modules//site-main"

  bucket = "${var.bucket}"
  random-id-domain-keeper = "${var.domain}"
  domain = "www.${var.domain}"
  domain-aliases = [ "www.${var.domain}" ]
}
```

#### Input

The `region` and `profile` inputs affect the AWS provider in the module.

*   __`bucket`__: The S3 bucket to create for deployment.
*   __`domain`__: The domain to provision.
*   __`domain-aliases`__: The domain aliases to use on the CloudFront
    distribution.
*   `random-id-domain-keeper`: The value to use as a keeper for the stable
    random duplicate content penalty secret output. Defaults to the `domain`
    input.
*   `routing-rules`: Special routing rules on the S3 bucket.
*   `not-found-response-path`: The response path for a missing resource.
*   `acm-certificate-arn`: The ARN for a Certificate issued or managed by AWS
    Certificate Manager. If missing, the distribution will use the default
    CloudFront certificate.
*   `default-ttl` (default 1 day): The default TTL for items in the
    distribution.
*   `max-ttl` (default 365 days): The maximum TTL for items in the
    distribution.

#### Output

*   `publish-user`: The name of the created publisher.
*   `publish-user-access-key`: The access key ID for the publisher.
*   `publish-user-secret-key`: The access key secret for the publisher.
*   `website-cdn-hostname`: The domain name of the CDN.
*   `website-cdn-zone-id`: The zone where the hostname of the CDN is hosted.
*   `duplicate-content-penalty-secret`: The stable random value for the
    duplicate-content protection mechanism.

### site-redirect

Creates all resources for an S3-based redirect website with a CloudFront
distribution. The site is always SSL-configured, but unless a a certificate
identifier is provided, the configuration will use the default CloudFront
certificate (this is not recommended). This *depends* on the preexistence of an
IAM user for the publisher.

This will create:

*   the website redirect bucket, and
*   a CloudFront distribution for the website bucket.

```terraform
module "site-main" {
  source = "github.com/halostatue/terraform-modules//site-main"

  bucket = "${var.bucket}"
  target = "www.${var.domain}"
  domain-aliases = [ "www.${var.domain}" ]
  publisher = "${module.site-main.publish-user}"
  duplicate-content-penalty-secret =
    "${module.site-main.duplicate-content-penalty-secret}"
}
```

#### Input

The `region` and `profile` inputs affect the AWS provider in the module.

*   __`bucket`__: The S3 bucket to create for deployment.
*   __`target`__: The domain to which this bucket/distribution will be
    redirected (always uses `https://`).
*   __`domain-aliases`__: The domain aliases to use on the CloudFront
    distribution.
*   __`publisher`__: The name of the publisher user.
*   `acm-certificate-arn`: The ARN for a Certificate issued or managed by AWS
    Certificate Manager. If missing, the distribution will use the default
    CloudFront certificate.
*   `default-ttl` (default 1 day): The default TTL for items in the
    distribution.
*   `max-ttl` (default 365 days): The maximum TTL for items in the
    distribution.

#### Output

*   `redirect-cdn-hostname`: The domain name of the CDN.
*   `redirect-cdn-zone-id`: The zone where the hostname of the CDN is hosted.

[Terraform]: https://www.terraform.io/
[Ringo De Smet]: https://ringo.de-smet.name
[scripts]: https://github.com/ringods/terraform-website-s3-cloudfront-route53
[Modules documentation]: https://www.terraform.io/docs/modules/sources.html#github
[duplicate content penalty]: https://support.google.com/webmasters/answer/66359?hl=en
