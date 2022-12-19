# Migrating Between Versions

## Migrating from v4 to v5

`halostatue/terraform-modules` v5 has migrations that need to be executed on
upgrade. Some of these changes will be captured cleanly with [tfautomv][].

> I personally prefer running `tfautomv -output commands` and running the state
> migration commands myself, but if you prefer keeping a `moves.tf` file, that
> is the default mode for `tfautomv`.

### Migrating `aws/content-site` Resources

The following migrations assume a module definition like this:

```terraform
module "content" {
  source = "github.com/halostatue/terraform-modules//aws/content-site?ref=v5.x"

  site-name   = "www"
  domain-name = "example.com"
  default-ttl = 300
  max-ttl     = 3600

  acm-certificate-arn = "some-arn-cetificate"
}

module "redirect" {
  source = "github.com/halostatue/terraform-modules//aws/redirect-site?ref=v5.x"

  site-name   = "www"
  domain-name = "example.com"
  default-ttl = 300
  max-ttl     = 3600

  acm-certificate-arn = "some-arn-cetificate"
}
```

#### Key Rotation Requires Publisher Key Moves

The publisher key `module.content.aws_iam_access_key.publisher` needs to be
moved to `module.content.aws_iam_access_key.publisher-access-key["v1"]`. This
should be handled by `tfautomv`.

#### Module Resource Names Have Been Normalized

The following resource moves are not seen by `tfautomv`.

##### `content-site`

- `module.content.aws_cloudfront_distribution.content` to
  `module.content.aws_cloudfront_distribution.distribution`
- `module.content.aws_iam_user.publisher` to
  `module.content.aws_iam_user.publisher[0]`
- `module.content.aws_iam_policy_attachment.publisher` to
  `module.content.aws_iam_policy_attachment.publisher[0]`
- `module.content.aws_iam_policy_attachment.publisher` to
  `module.content.aws_iam_policy_attachment.publisher[0]`
- `module.content.aws_route53_record.dns-record` to
  `module.content.aws_route53_record.dns-record[0]`

##### `redirect-site`

- `module.redirect.aws_cloudfront_distribution.redirect` to
  `module.redirect.aws_cloudfront_distribution.distribution`

#### Adding Bucket Ownership Control May Require ACL Surgery

The log bucket may have ACLs applied that must be manually removed before the
bucket ownership control can be properly applied, as destroying the ACL resource
in Terraform does not remove the ACL resource from the bucket.

#### Public Policy Access vs Public Access Block

Specifying `block_public_policy` on an S3 bucket Public Access Block will
prevent writing the required public policy to serve the website. If errors occur
around adding this, add `block-public-policy = false` to the content block and
apply a couple of times until the policy is added.

#### Outputs Have Changed

The output structure has changed.

## Migrating from v3 to v4

`halostatue/terraform-modules` v4 has several migrations that need to be managed
because of incompatibilities between the AWS provider v3 and v4, and one
migration due to a dropped resource.

### Migrating `aws/s3-tfstate-bucket` Resources

The module `aws/s3-tfstate-bucket` has been removed and needs to be migrated
into standard terraform definitions or an internal module.

1. Remove the module. Note the name of the bucket. We are assuming
   `terraform-state-bucket` for this example.

   ```diff
   -module "tfstate_bucket" {
   -  source = "github.com/halostatue/terraform-modules//aws/s3-tfstate-bucket?ref=v3.x"
   -
   -  bucket = "terraform-state-bucket"
   -  user   = aws_iam_user.terraformer.name
   -}
   ```

2. Add the resources that the module defines. This includes the changes required
   to work with the AWS provider v4.

   ```diff
   +resource "aws_s3_bucket" "terraform-state-bucket" {
   +  bucket = "terraform-state-bucket"
   +
   +  lifecycle {
   +    prevent_destroy = true
   +    ignore_changes = [
   +      lifecycle_rule
   +    ]
   +  }
   +}
   +
   +resource "aws_s3_bucket_acl" "terraform-state-bucket" {
   +  bucket = aws_s3_bucket.terraform-state-bucket.id
   +  acl    = "private"
   +}
   +
   +resource "aws_s3_bucket_versioning" "terraform-state-bucket" {
   +  bucket = aws_s3_bucket.terraform-state-bucket.id
   +  versioning_configuration {
   +    status = "Enabled"
   +  }
   +}
   +
   +resource "aws_s3_bucket_lifecycle_configuration" "terraform-state-bucket" {
   +  bucket     = aws_s3_bucket.terraform-state-bucket.id
   +  depends_on = [aws_s3_bucket_versioning.terraform-state-bucket]
   +
   +  rule {
   +    id     = "tfstate"
   +    status = "Enabled"
   +
   +    noncurrent_version_expiration {
   +      noncurrent_days = 90
   +    }
   +  }
   +}
   +
   +resource "aws_s3_bucket_public_access_block" "terraform-state-bucket" {
   +  bucket              = aws_s3_bucket.terraform-state-bucket.id
   +  block_public_acls   = true
   +  block_public_policy = true
   +}
   +
   +resource "aws_iam_user_policy" "terraform-state-bucket-policy" {
   +  name = "TerraformAccess-terraform-state-bucket"
   +  user = aws_iam_user.terraformer.name
   +
   +  policy = jsonencode({
   +    Version = "2012-10-17"
   +    Statement = [
   +      {
   +        Effect = "Allow"
   +        Action = ["s3:*"]
   +        Resource = [
   +          aws_s3_bucket.terraform-state-bucket.arn,
   +          "${aws_s3_bucket.terraform-state-bucket.arn}/*",
   +        ]
   +      }
   +    ]
   +  })
   +}
   +
   +output "terraform-state-bucket-id" {
   +  value = aws_s3_bucket.terraform-state-bucket.id
   +}
   ```

3. Migrate the terraform resources in your state (this assumes that
   `aws_iam_user.terraformer.name` is `terraformer`):

   ```sh
   terraform state mv module.tfstate_bucket.aws_s3_bucket.terraform aws_s3_bucket.terraform-state-bucket
   terraform state mv module.tfstate_bucket.aws_iam_user_policy.terraform terraformer:TerraformAccess-terraform-state-bucket
   ```

4. Import new missing resources:

   ```sh
   terraform import aws_s3_bucket_versioning.terraform-state-bucket terraform-state-bucket
   terraform import aws_s3_bucket_lifecycle_configuration.terraform-state-bucket terraform-state-bucket
   terraform import aws_s3_bucket_acl.terraform-state-bucket terraform-state-bucket,private
   ```

5. Plan and apply the changes as normal.

### Migrations for `aws/content-site` and `aws/redirect-site`

The terraform provider for AWS has been upgrade to `~> 4.0`, which necessitated
changes to how S3 buckets are defined. Various configurations like bucket ACLs
are now treated as separate resources, necessitating `terraform import` to
prevent data loss.

> Note: some parts of this can be done with [tfedit][] and [tfmigrate][].

#### `terraform import` New Resources

Assuming a module declaration like this:

```
module "content" {
  source = "github.com/halostatue/terraform-modules//aws/content-site?ref=v4.x"
  domain = "www.example.com"
}
```

The following `terraform import` commands need to be run:

```sh
terraform import module.content.aws_s3_bucket_acl.logs www-example-com-logs,log-delivery-write
terraform import module.content.aws_s3_bucket_logging.bucket www-example-com
terraform import module.content.aws_s3_bucket_policy.bucket www-example-com
terraform import module.content.aws_s3_bucket_website_configuration.bucket www-example-com
```

The `terraform import` commands for `aws/redirect-site` will be similar, but
shorter:

```sh
terraform import module.redirect.aws_s3_bucket_policy.bucket www-example-com-redirect
terraform import module.redirect.aws_s3_bucket_website_configuration.bucket www-example-com-redirect
```

## Migrating from v2 to v3

`halostatue/terraform-modules` v3 has various changes. Most of these will be
handled by normal upgrades from Terraform 0.8 to 0.13 or higher without any
state migration or rebuilding.

However, `aws/s3-tfstate-folder` was removed without replacement because it is
a module that exists only to produce output useful for old terraform remote
state configuration. The information it provided needs to be used in a proper
`backend` module:

```terraform
terraform {
  backend "s3" {
    bucket  = "terraform-state-bucket"
    key     = "terraform.tfstate"
    region  = "ca-central-1"
    profile = "terraformer"
  }
}
```

When upgrading my personal infrastructure to use the v3 modules, I migrated my
infrastructure because I switched from multiple infrastructure folders (one per
module) with separate state to a single infrastructure folder with single state.

[tfedit]: https://github.com/minamijoyo/tfedit
[tfmigrate]: https://github.com/minamijoyo/tfmigrate
[tfautomv]: https://github.com/padok-team/tfautomv
