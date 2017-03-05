data "terraform_remote_state" "terraformers" {
  backend = "s3"

  config {
    bucket = "example-com-infrastructure"
    key = "terraformers/terraform.tfstate"
    region = "us-east-1"
    profile = "terraformer"
  }
}
