module "redirect" {
  source = "github.com/halostatue/terraform-modules//aws/redirect-site?ref=v2.0"

  bucket              = "www.example.com-redirect"
  domain              = "example.com"
  target              = "www.example.com"
  publisher           = "${data.terraform_remote_state.example_com_content.publisher}"
  content-key         = "${data.terraform_remote_state.example_com_content.content-key}"
  default-ttl         = 300
  max-ttl             = 3600
  acm-certificate-arn = "arn:aws:acm:us-east-1:<account-id>:certificate/<cert-id>"
}

output "cdn-id" {
  value = "${module.redirect.cdn-id}"
}

output "cdn-aliases" {
  value = "${module.redirect.cdn-aliases}"
}

output "cdn-domain" {
  value = "${module.redirect.cdn-domain}"
}

output "cdn-zone-id" {
  value = "${module.redirect.cdn-zone-id}"
}
