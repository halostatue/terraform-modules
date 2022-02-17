# Terraform Module: aws/s3-tfstate-bucket

Creates an S3 bucket (with versioning and a 90 day lifecycle policy) with a
user to store the Terraform state remotely.

```terraform
module "tfstate_bucket" {
  source = "github.com/halostatue/terraform-modules//aws/s3-tfstate"

  prefix = "${var.bucket}"
}
```

## Input

- **`bucket`**: The bucket to create for storing Terraform state.
- **`user`**: The user for which permissions will be granted on this bucket.
- `expiration-days`: The number of days until the non-current version
  expires. Defaults to 90 days.

## Output

- `id`: The ID of the bucket used to store the Terraform state.
  with the bucket provided.
