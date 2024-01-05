# Terraform Modules

This repository contains the [Terraform][] modules required to setup a static
website, hosted out of an S3 bucket. The site is fronted by a CloudFront
distribution, can use AWS Certificate Manager for HTTPS and allows for
configuring the required DNS entries in Route53.

The modules also take care of:

- preventing the origin bucket being indexed by search bots (avoiding the
  Google [duplicate content penalty][]);
- redirect other domains to the main site with proper rewriting;
- properly handling CORS configuration;
- access logging; and
- redirecting HTTP to HTTPS.

This is version 5.4.0, tagged variously as `v5.4.0`, `v5.4.x`, and `v5.x`, which
can be specified in a`module source` as:

- `github.com/halostatue/terraform-modules//`_`<module>`_`?ref=v5.4.0`
- `github.com/halostatue/terraform-modules//`_`<module>`_`?ref=v5.4.x`
- `github.com/halostatue/terraform-modules//`_`<module>`_`?ref=v5.x`

There are special upgrade instructions for this version, see the documents
[CHANGELOG](CHANGELOG.md) and [MIGRATION](MIGRATION.md)>

## Introduction

There are multiple modules provided in this repository, generally based around
my needs, but also to work around the lack of conditional and compositional
logic in Terraform.

This release has removed the previously provided examples until they can be
reworked from the current consumers of these modules.

Each module has its own README which should be read before using.

### `aws/content-site` and `aws/redirect-site`

These two modules are used to create S3 buckets to serve a static website,
fronted by CloudFront. With these modules, you can:

- Create a single site on a subdomain (https://www.example.com/).
- Create a single site on an apex domain (https://example.com/).
- Create the main site on a subdomain (https://www.example.com/) and
  redirecting the naked domain (https://example.com/) to the subdomain.
- Create the main site on an apex domain (https://example.com/) and
  redirecting the subdomain (https://www.example.com/) to the apex domain.

These modules do not support creating non-SSL sites, but they are configurable
to either use the default CloudFront certificate (which will result in identity
warnings) or an AWS Certificate Manager-based certificate (which must be
configured manually prior to using these scripts).

> **Note**: AWS Certificate Manager supports multiple regions, but CloundFront
> appears to have a restriction that those certificates must be requested in
> us-east-1.

Read more about:

- [`aws/content-site`][]
- [`aws/redirect-site`][]

## Versioning

`halostatue/terraform-modules` aims to mostly follow [Semantic Versioning][],
noted by `git` tags. Major tags (e.g., `v5.x`) will move with the most recent
minor release of a version (it will move from `v5.0.x` to `v5.1.x` as
appropriate). Minor tags (e.g., `v5.0.x`) will move with the patch releases, if
necessary.

It is strongly recommended you use the `ref` to select a specific tag, as there
may be incompatible changes in future versions, and `master` may be considered
unstable.

## Contributors

- Austin Ziegler derived the initial versions of these modules from [scripts][]
  by [Ringo De Smet][].

  - Further work was done in conjunction with Kinetic Commerce where we had
    originally adopted derivations on the modules in this repo. With version
    5.x, Kinetic Commerce will be using this module for website-like buckets.

[terraform]: https://www.terraform.io/
[ringo de smet]: https://ringo.de-smet.name
[scripts]: https://github.com/ringods/terraform-website-s3-cloudfront-route53
[duplicate content penalty]: https://support.google.com/webmasters/answer/66359?hl=en
[semantic versioning]: http://semver.org/
[`aws/content-site`]: https://github.com/halostatue/terraform-modules/tree/v2.0/aws/content-site
[`aws/redirect-site`]: https://github.com/halostatue/terraform-modules/tree/v2.0/aws/redirect-site
