# Terraform Module: aws/s3-tfstate-bucket

This module is a trick. It doesn’t actually *do* anything on a remote server.
Given the right inputs, however, it will produce useful outputs.

```terraform
module "folder_terraformers" {
  source = "github.com/halostatue/terraform-modules//aws/s3-tfstate-folder?ref=v2.0"

  aws-profile = "${var.profile}"
  aws-region  = "${var.region}"

  bucket = "${module.tfstate_bucket.id}"
  user   = "${aws_iam_user.terraformer.name}"
  folder = "terraformers"
}

output "terraformers-command" {
  value = "${module.folder_terraformers.command}"
}

output "terraformers-config" {
  value = "${module.folder_terraformers.config}"
}
```

## Input

*   __`bucket`__: The bucket that stores terraform state.
*   __`user`__: The user with permissions to access the terraform state bucket.
*   __`folder`__: The name to use for this tfstate folder.
*   `aws-region`: The optional name of the AWS Region to use for website.
*   `aws-profile` The optional name of the AWS CLI profile name to use for this
    website.

## Output

*   `command`: The `terraform remote config` command required to use this
    folder bucket for remote configuration.
*   `config`: The `data "terraform_state"` resource required to use this folder
    bucket in other environments.

### Note

These outputs are designed to be consumed by the script
`example/terraformers/tf`.
