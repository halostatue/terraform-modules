data "terraform_remote_state" "content" {
  backend = "s3"

  config {
    bucket = "example-com-infrastructure"
    key = "content/terraform.tfstate"
    region = "us-east-1"
    profile = "terraformer"
  }
}
