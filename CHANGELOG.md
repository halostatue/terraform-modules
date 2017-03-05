## 2.0 / 2017-03-12

-   This version is incompatible with previous versions and the structure
    inherited from the modules created by Ringo De Smet.

-   The canonical way to use these is shown in [`example/`][], which
    ties together multiple related Terraform environments with scripts that
    link everything together, as [recommended by Charity Majors][].

-   It is possible to do an in-place migration from version 1.x of these
    scripts with only a few (substantial) edits to the original scripts, but
    there is a chance for data loss or a need to edit your `tfstate` file. As
    such, this course is not recommended.

-   All Route53 modules have been removed. They are small enough that they add
    no value over direct Route 53 resource allocation.

-   All modules for AWS are now in [`aws/`][], providing module namespacing.
    Previous common input variables `region` and `profile` have been renamed
    `aws-region` and `aws-profile`, respectively.

-   The `tfstate` module has been split into `aws/s3-tfstate-bucket` and
    `aws/s3-tfstate-folder`. See the README for instructions on how to use
    these.

-   The `site-main` module has been renamed to `aws/content-site` and many of
    its inputs and outputs have been renamed and/or changed.

-   The `site-redirect` module has been renamed to `aws/redirect-site` and many
    of its inputs and outputs have been renamed and/or changed.

-   Changes to `site-main` (renamed to `aws/content-site`):

    -   Input `random-id-domain-keeper` has been renamed to `content-key-base`.
    -   Input `bucket` has been made optional with a default of `domain`.
    -   Input `domain-aliases` is now optional. When domain aliases are set for
        the CloudFront distribution, it always include
        `["${list("${var.domain}")}"]`.
    -   Publisher outputs have been changed: `publish-user` was renamed to
        `publisher`. `publish-user-access-key` and `publish-user-secret-key`
        have been replaced with a sensitive map `publisher-access-key` with
        keys `id` and `secret`. It is no longer recommended that these be
        printed from the primary module, but instead be printed with an
        explicit `-module` tag from `terraform output`.
    -   Output `duplicate-content-penalty-secret` has been renamed to
        `content-key`. Its use is the same.
    -   Outputs `website-cdn-*` have had the `website-` prefix removed.

-   Changes to `tfstate` (split into `aws/s3-tfstate-bucket` and
    `aws/s3-tfstate-folder`)::

    -   `aws/s3-tfstate-bucket` is used to create the versioned tfstate bucket,
        with a default 90 day expiration (set with `expiration-days`). Both
        `bucket` and `user` are now required parameters, and both `prefix` and
        `tfstate-prefix` have been removed. The `user` will not be created, but
        only have a policy assigned.

    -   `aws/s3-tfstate-folder` is an output-only module that generates the
        output necessary to configure remote access both as a `terraform`
        command and as values to use for a `data "terraform_remote_state"`
        configuration.

## 1.0 / 2017-02-14

-    New release versioning because these are modified from Ringo De Smet’s.
-    Added a VERSION file.
-    Known to be compatible with Terraform 0.8.

[recommended by Charity Majors]: https://charity.wtf/2016/03/30/terraform-vpc-and-why-you-want-a-tfstate-file-per-env/
[`example/`]: https://github.com/halostatue/terraform-modules/tree/v2.0/example/
[`aws/`]: https://github.com/halostatue/terraform-modules/tree/v2.0/aws/
