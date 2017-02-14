variable "region" {
  default = "ca-central-1"
  description = "The region for the deployment bucket."
}
variable "bucket" {
  description = "The S3 bucket to create for deployment"
}
variable "domain" {
  description = "The name of the domain to provision."
}
variable "profile" {
  description = "The AWS profile to use from the credentials file."
}
