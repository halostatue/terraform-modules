module "folder_content" {
  source = "github.com/halostatue/terraform-modules//aws/s3-tfstate-folder?ref=v2.0"

  aws-profile = "${var.profile}"
  aws-region  = "${var.region}"

  bucket = "${module.tfstate_bucket.id}"
  user   = "${aws_iam_user.terraformer.name}"
  folder = "content"
}

output "content-command" {
  value = "${module.folder_content.command}"
}

output "content-config" {
  value = "${module.folder_content.config}"
}
