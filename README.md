# Terraform Modules

This repository contains the [Terraform][] modules required to setup a static
website, hosted out of an S3 bucket. The site is fronted by a CloudFront
distribution, can use AWS Certificate Manager for HTTPS and allows for
configuring the required DNS entries in Route53.

The modules also take care of:

*   preventing the origin bucket being indexed by search bots (avoiding the
    Google [duplicate content penalty][]);
*   redirect other domains to the main site with proper rewriting;
*   access logging; and
*   redirecting HTTP to HTTPS.

These modules are derived from [scripts][] by [Ringo De Smet][].

> NOTE: This README describes v2 of these modules, which are incompatible with
> v1 of the modules and have diverged from the original versions.

## Versioning

halostatue/terraform-modules aims to mostly follow [Semantic Versioning][],
noted by `git` tags. A Major tag (e.g., `v2`) will move with the most recent
minor release of a version (it will move from `v2.0` to `v2.1` as appropriate).
There will be no patch versions tagged.

This is version 2.0, tagged as `v2.0`, which can be specified in a`module
source` as:

*   `github.com/halostatue/terraform-modules//`*`<module>`*`?ref=v2.0`
*   `github.com/halostatue/terraform-modules//`*`<module>`*`?ref=v2`

It is strongly recommended you use the `ref` to select a specific branch, as
there may be incompatible changes in future versions, and `master` may be
considered unstable.

## Introduction

There are multiple modules provided in this repository, generally based around
my needs, but also to work around the lack of conditional and compositional
logic in Terraform. These modules are not meant to be run by themselves; see
the `example/` directory for an example configuration and wrapper script.

Each module has its own README which should be read before using.

With the modules provided, you can compose everything you need to make various
types of configurations for S3 buckets served by .

*   Create a single site on a subdomain (https://www.example.com/).
*   Create a single site on an apex domain (https://example.com/).
*   Create the main site on a subdomain (https://www.example.com/) and
    redirecting the naked domain (https://example.com/) to the subdomain.
*   Create the main site on an apex domain (https://example.com/) and
    redirecting the subdomain (https://www.example.com/) to the apex domain.

These modules do not support creating non-SSL sites, but they are configurable
to either use the default CloudFront certificate (which will result in identity
warnings) or an AWS Certificate Manager-based certificate (which must be
configured manually prior to using these scripts).

> __Note__: AWS Certificate Manager supports multiple regions, but CloundFront
> appears to have a restriction that those certificates must be requested in
> us-east-1.

## Configuring Terraform

These modules are known to work with Terraform `0.8.x` and may not work a later
version.

### Provider Configuration

To simplify configuration, all of the AWS modules expect the root module to be
configured properly with a named AWS CLI crednetials profile (as found in
`${HOME}/.aws/credentials`) and to the appropriate region. The region and
profile may be overridden by specifying `aws-region` and `aws-profile` inputs
to the modules (`provider` aliases are not currently interpolated).

```terraform
variable "aws-region" {
  default = "us-east-1"
  description = "The region for the deployment bucket."
}
variable "aws-profile" {
  description = "The AWS profile to use from the credentials file."
  default = "default"
}

provider "aws" {
  region = "${var.aws-region}"
  profile = "${var.aws-profile}"
}

module "meta-tfstate" { # Uses the default provider configuration.
  source = "github.com/halostatue/terraform-modules//aws/s3-tfstate?ref=v2.0"

  # ...
}

module "domain-tfstate" { # Uses a different provider configuration.
  source = "github.com/halostatue/terraform-modules//aws/s3-tfstate?ref=v2.0"

  aws-region = "us-west-1"
  aws-profile = "terraform-state"

  # ...
}
```

### Module Source Selection

As noted in the Terraform [Modules documentation][], GitHub is treated as a
special source for modules. Each of the modules can be reached with the
appropriate source specification.

```terraform
module "site-tfstate" {
  source = "github.com/halostatue/terraform-modules//aws/s3-tfstate"
  # ...
}
```

## Provided Modules

If an input name is __`bold`__, it is required. Otherwise, it is optional.

### aws/s3-tfstate

Configures an S3 bucket (with versioning and a 90 day lifecycle policy) and
user (with policy) to store the Terraform state remotely. It is recommended
that the user created for working with Terraform be imported once this module
is present, but before application.

```terraform
module "my-site-tfstate" {
  source = "github.com/halostatue/terraform-modules//aws/s3-tfstate"

  prefix = "${var.bucket}"
}
```

Once created, terraform must be configured with the appropriate output. This
can be retrieved with `terraform output` for the module.

```sh
terraform output -module=my-site-tfstate
```

#### Input

The `aws-region` and `aws-profile` inputs affect the AWS provider in the
module.

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

### content-site

Creates all resources for an S3-based static website with a CloudFront
distribution. The site is always SSL-configured, but unless a a certificate
identifier is provided, the configuration will use the default CloudFront
certificate (this is not recommended).

This will create:

*   the website bucket,
*   a logging bucket,
*   a publisher user,
*   an IAM access key for the publisher, and
*   a CloudFront distribution for the website bucket.

```terraform
module "my-content-site" {
  source = "github.com/halostatue/terraform-modules//content-site?ref=v2.0"

  bucket = "${var.bucket}"
  dcps-key = "${var.domain}"
  domain = "www.${var.domain}"
  domain-aliases = [ "www.${var.domain}" ]
}
```

#### Input

The `aws-region` and `aws-profile` inputs affect the AWS provider in the
module.

*   __`bucket`__: The S3 bucket to create for deployment.
*   __`domain`__: The domain to provision.
*   __`domain-aliases`__: The domain aliases to use on the CloudFront
    distribution.
*   `content-key-base`: The base value of the content key used to prevent
    duplicate content penalties from being applied by Google. Defaults to the
    `domain` input.
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

*   `publisher`: The name of the
*   `publish-user`: The name of the created publisher.
*   `publish-user-access-key`: The access key ID for the publisher.
*   `publish-user-secret-key`: The access key secret for the publisher.
*   `cdn-hostname`: The domain name of the CDN.
*   `cdn-zone-id`: The zone where the hostname of the CDN is hosted.
*   `duplicate-content-penalty-secret`: The stable random value for the
    duplicate-content protection mechanism.

### redirect-site

Creates all resources for an S3-based redirect website with a CloudFront
distribution. The site is always SSL-configured, but unless a a certificate
identifier is provided, the configuration will use the default CloudFront
certificate (this is not recommended). This *depends* on the preexistence of an
IAM user for the publisher.

This will create:

*   the website redirect bucket, and
*   a CloudFront distribution for the website bucket.

```terraform
module "my-redirect-site" {
  source = "github.com/halostatue/terraform-modules//redirect-site?ref=v2.0"

  bucket = "${var.bucket}"
  target = "www.${var.domain}"
  domain-aliases = [ "www.${var.domain}" ]
  publisher = "${module.my-content-site.publish-user}"
  duplicate-content-penalty-secret =
    "${module.my-content-site.duplicate-content-penalty-secret}"
}
```

#### Input

The `aws-region` and `aws-profile` inputs affect the AWS provider in the
module.

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

*   `cdn-hostname`: The domain name of the CDN.
*   `cdn-zone-id`: The zone where the hostname of the CDN is hosted.

[Terraform]: https://www.terraform.io/
[Ringo De Smet]: https://ringo.de-smet.name
[scripts]: https://github.com/ringods/terraform-website-s3-cloudfront-route53
[Modules documentation]: https://www.terraform.io/docs/modules/sources.html#github
[duplicate content penalty]: https://support.google.com/webmasters/answer/66359?hl=en
[Semantic Versioning]: http://semver.org/
