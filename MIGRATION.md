# Migrating Between Versions

## Migrating to v3

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

## Migrating to v4

`halostatue/terraform-modules` v4 has several migrations that need to be managed
because of incompatibilities between the AWS provider v3 and v4, and one
migration due to a dropped resource.

### Migrating `aws/s3-tfstate-bucket` Resources

The module `aws/s3-tfstate-bucket` has been removed and needs to be migrated
into standard terraform definitions or an internal module. Strictly speaking,
this should have been removed for the v3 release, but there were enough other
changes that it was missed.

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

#### `terraform import` New Resources

Assuming a module declaration like this:

```
module "main_site" {
  source = "github.com/halostatue/terraform-modules//aws/content-site?ref=v4.x"
  domain = "www.example.com"
}
```

The following `terraform import` commands need to be run:

```sh
terraform import module.main_site.aws_s3_bucket_acl.logs www-example-com-logs,log-delivery-write
terraform import module.main_site.aws_s3_bucket_logging.bucket www-example-com
terraform import module.main_site.aws_s3_bucket_policy.bucket www-example-com
terraform import module.main_site.aws_s3_bucket_website_configuration.bucket www-example-com
```

The `terraform import` commands for `aws/redirect-site` will be similar, but
shorter:

```sh
terraform import module.redirect_site.aws_s3_bucket_policy.bucket www-example-com-redirect
terraform import module.NAME.aws_s3_bucket_website_configuration.bucket www-example-com-redirect
```

#### Removed `routing-rules` configuration

The `aws_s3_bucket_website_configuration` resource does not allow assignment of
routing rules as the 3.x terraform provider. Because of this, it is no longer
possible to pass in `routing-rules` for configuration and should be removed.

If the `routing-rules` were important to your site's definition, it is
recommended that you migrate the resources out of the `aws/content-site` module
as straight definitions.
