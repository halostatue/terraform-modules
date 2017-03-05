data "terraform_remote_state" "redirect" {
  backend = "s3"

  config {
    bucket = "example-com-infrastructure"
    key = "redirect/terraform.tfstate"
    region = "us-east-1"
    profile = "terraformer"
  }
}
