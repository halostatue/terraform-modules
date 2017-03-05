module "content" {
  source = "github.com/halostatue/terraform-modules//aws/content-site?ref=v2.0"

  domain              = "www.example.com"
  default-ttl         = 300
  max-ttl             = 3600
  acm-certificate-arn = "arn:aws:acm:us-east-1:<account-id>:certificate/<cert-id>"
}

output "publisher" {
  value = "${module.content.publisher}"
}

output "publisher-access-key" {
  value = "${module.content.publisher-access-key}"
}

output "bucket-name" {
  value = "${module.content.bucket-name}"
}

output "cdn-id" {
  value = "${module.content.cdn-id}"
}

output "cdn-aliases" {
  value = "${module.content.cdn-aliases}"
}

output "cdn-domain" {
  value = "${module.content.cdn-domain}"
}

output "cdn-zone-id" {
  value = "${module.content.cdn-zone-id}"
}

output "content-key" {
  value = "${module.content.content-key}"
}
