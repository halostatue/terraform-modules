module "folder_dns" {
  source = "github.com/halostatue/terraform-modules//aws/s3-tfstate-folder?ref=v2.0"

  aws-profile = "${var.profile}"
  aws-region  = "${var.region}"

  bucket = "${module.tfstate_bucket.id}"
  user   = "${aws_iam_user.terraformer.name}"
  folder = "dns"
}

output "dns-command" {
  value = "${module.folder_dns.command}"
}

output "dns-config" {
  value = "${module.folder_dns.config}"
}
