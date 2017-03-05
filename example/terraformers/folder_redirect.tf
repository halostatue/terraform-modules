module "folder_redirect" {
  source = "github.com/halostatue/terraform-modules//aws/s3-tfstate-folder?ref=v2.0"

  aws-profile = "${var.profile}"
  aws-region  = "${var.region}"

  bucket = "${module.tfstate_bucket.id}"
  user   = "${aws_iam_user.terraformer.name}"
  folder = "redirect"
}

output "redirect-command" {
  value = "${module.folder_redirect.command}"
}

output "redirect-config" {
  value = "${module.folder_redirect.config}"
}
