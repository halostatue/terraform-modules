module "tfstate_bucket" {
  source = "github.com/halostatue/terraform-modules//aws/s3-tfstate-bucket?ref=v2.0"

  bucket = "example-com-infrastructure"
  user   = "${aws_iam_user.terraformer.name}"
}
