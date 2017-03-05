data "terraform_remote_state" "dns" {
  backend = "s3"

  config {
    bucket = "example-com-infrastructure"
    key = "dns/terraform.tfstate"
    region = "us-east-1"
    profile = "terraformer"
  }
}
