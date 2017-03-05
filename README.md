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
the [`example/`][] directory for an example configuration and wrapper script.

Each module has its own README which should be read before using.

### `aws/s3-tfstate-bucket` and `aws/s3-tfstate-folder`

These two modules are used to create and manage the bucket that holds all of
the Terraform shared state.

Read more about:

*  [`aws/s3-tfstate-bucket`][]
*  [`aws/s3-tfstate-folder`][]

### `aws/content-site` and `aws/redirect-site`

These two modules are used to create S3 buckets to serve a static website,
fronted by CloudFront. With these modules, you can:

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

Read more about:

*   [`aws/content-site`][]
*   [`aws/redirect-site`][]

[Terraform]: https://www.terraform.io/
[Ringo De Smet]: https://ringo.de-smet.name
[scripts]: https://github.com/ringods/terraform-website-s3-cloudfront-route53
[duplicate content penalty]: https://support.google.com/webmasters/answer/66359?hl=en
[Semantic Versioning]: http://semver.org/

[`example/`]: https://github.com/halostatue/terraform-modules/tree/v2.0/example
[`aws/content-site`]: https://github.com/halostatue/terraform-modules/tree/v2.0/aws/content-site
[`aws/redirect-site`]: https://github.com/halostatue/terraform-modules/tree/v2.0/aws/redirect-site
[`aws/s3-tfstate-bucket`]: https://github.com/halostatue/terraform-modules/tree/v2.0/aws/s3-tfstate-bucket
[`aws/s3-tfstate-folder`]: https://github.com/halostatue/terraform-modules/tree/v2.0/aws/s3-tfstate-folder
