# Changelog

## 5.0.0 / 2022-02-19

- For all modules:

  - `output.tf`, `variables.tf`, `versions.tf` have been extracted if they were
    not already.

  - Normalized variable names to use `kebab-case`.

  - Reshaped the outputs.

- `aws/content-site`:

  - Enabled key rotation on `aws/content-site` created publisher users.

  - Restored `var.routing-rules` into `aws/content-site` module.

- Updated [MIGRATION.md](MIGRATION.md) for v4 to v5 upgrades.

## 4.0.0 / 2022-02-17

- Removed `aws/s3-tfstate-bucket` module. This was created for early versions of
  Terraform remote state management, and is no longer useful as a separate
  module. Follow the instructions in
  [MIGRATION.md](MIGRATION.md#migrating-aws%2Fs3-tfstate-bucket-resources).

- Removed `var.routing-rules` from `aws/content-site` and `aws/redirect-site`
  modules. Assignment of routing rules from variables is no longer supported by
  the AWS provider.

- Updated to support terraform-provider-aws 4.0. After upgrading it is necessary
  to import items to your local state to prevent data loss. Follow the
  instructions in [MIGRATION.md](MIGRATION.md#migrating-v3-to-v4).

## 3.1.1 / 2022-02-17

- Added a lifecycle rule to `content-site.aws_s3_bucket.logs` bucket to prevent
  the log from growing forever. Defaults to 30 days.

## 3.1.0 / 2022-02-16

- Removed `var.aws-region` and `var.aws-profile` from all modules. Use provider
  inheritance or aliases instead.

  ```terraform
  provider "aws" {
    alias    = "usw2"
    provilde = "default"
    region   = "us-west-2"
  }

  module "terraform-bucket" {
    source = "github.com/halostatue/terraform-modules//aws/s3-tfstate-bucket?ref=v3.x"

    providers = {
      aws = aws.usw2
    }
  }
  ```

- Added a `/destroyable` sub-module that removes resource lifecycle management.
  To destroy a resource set using this module, there are multiple steps to be
  taken. Assuming a module like the following:

  ```
  module "terraform-bucket" {
    source = "github.com/halostatue/terraform-modules//aws/s3-tfstate-bucket?ref=v3.x"
  }
  ```

  The module declaration would be changed to:

  ```
  module "terraform-bucket" {
    source = "github.com/halostatue/terraform-modules//aws/s3-tfstate-bucket/destroyable?ref=v3.x"

    count = 0
  }
  ```

  Any `output` values referring to the module would need to be removed and then
  it is necessary to run `terraform init` followed by a `plan` or `apply` to
  remove the resource. After this, the module reference can be removed.

  The resource and its `/destroyable` counterpart will be kept in sync across
  versions.

## 3.0.0 / 2022-02-04

- Update modules to support Terraform 1.1.5+. These files should work with
  versions `>= 0.13`.

- Numerous changes required to work with Terraform > 0.8.

- Add a `terraform` block indicating `required_providers` for the modules.

- Removed the use of `template_file` and replaced with a `locals` block.

- Added `lifecycle { prevent_destroy = true }` blocks to buckets and publisher
  user so that destruction is prevented by default.

- Added `lifecycle { create_before_destroy = true }` block to the publisher IAM
  access key.

- Removed data blocks for policies and replaced with `jsonencode({…})` policy
  definitions.

- Simplified outputs.

- Added variable validation.

- Remove out-of-date examples.

- Added `aws/create-certificate` for creating automatic certificate management.

- Add tags to everything that can be tagged.

- Modification to client repos will be required.

  - All module references must be updated to the current tag (`v3`).

  - All modules now explicitly require `aws-profile` and `aws-region` be
    specified.

## 2.0 / 2017-03-12

- This version is incompatible with previous versions and the structure
  inherited from the modules created by Ringo De Smet.

- The canonical way to use these is shown in [`example/`], which ties together
  multiple related Terraform environments with scripts that link everything
  together, as [recommended by Charity Majors].

- It is possible to do an in-place migration from version 1.x of these scripts
  with only a few (substantial) edits to the original scripts, but there is
  a chance for data loss or a need to edit your `tfstate` file. As such, this
  course is not recommended.

- All Route53 modules have been removed. They are small enough that they add no
  value over direct Route 53 resource allocation.

- All modules for AWS are now in [`aws/`], providing module namespacing.
  Previous common input variables `region` and `profile` have been renamed
  `aws-region` and `aws-profile`, respectively.

- The `tfstate` module has been split into `aws/s3-tfstate-bucket` and
  `aws/s3-tfstate-folder`. See the README for instructions on how to use these.

- The `site-main` module has been renamed to `aws/content-site` and many of its
  inputs and outputs have been renamed and/or changed.

- The `site-redirect` module has been renamed to `aws/redirect-site` and many of
  its inputs and outputs have been renamed and/or changed.

- Changes to `site-main` (renamed to `aws/content-site`):

  - Input `random-id-domain-keeper` has been renamed to `content-key-base`.

  - Input `bucket` has been made optional with a default of `domain`.

  - Input `domain-aliases` is now optional. When domain aliases are set for the
    CloudFront distribution, it always include `["${list("${var.domain}")}"]`.

  - Publisher outputs have been changed: `publish-user` was renamed to
    `publisher`. `publish-user-access-key` and `publish-user-secret-key` have
    been replaced with a sensitive map `publisher-access-key` with keys `id` and
    `secret`. It is no longer recommended that these be printed from the primary
    module, but instead be printed with an explicit `-module` tag from
    `terraform output`.

  - Output `duplicate-content-penalty-secret` has been renamed to `content-key`.
    Its use is the same.

  - Outputs `website-cdn-*` have had the `website-` prefix removed.

- Changes to `tfstate` (split into `aws/s3-tfstate-bucket` and
  `aws/s3-tfstate-folder`)::

  - `aws/s3-tfstate-bucket` is used to create the versioned tfstate bucket, with
    a default 90 day expiration (set with `expiration-days`). Both `bucket` and
    `user` are now required parameters, and both `prefix` and `tfstate-prefix`
    have been removed. The `user` will not be created, but only have a policy
    assigned.

  - `aws/s3-tfstate-folder` is an output-only module that generates the output
    necessary to configure remote access both as a `terraform` command and as
    values to use for a `data "terraform_remote_state"` configuration.

## 1.0 / 2017-02-14

- New release versioning because these are modified from Ringo De Smet’s.

- Added a VERSION file.

- Known to be compatible with Terraform 0.8.

[recommended by charity majors]: https://charity.wtf/2016/03/30/terraform-vpc-and-why-you-want-a-tfstate-file-per-env/
[`example/`]: https://github.com/halostatue/terraform-modules/tree/v2.0/example/
[`aws/`]: https://github.com/halostatue/terraform-modules/tree/v2.0/aws/
