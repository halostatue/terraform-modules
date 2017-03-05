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
