variable "region" { default = "" }
variable "profile" { default = "" }
variable "bucket" {}
variable "publisher" {}
variable "target" {}
variable "duplicate-content-penalty-secret" {}
variable "acm-certificate-arn" { default = "" }
variable "domain-aliases" { type = "list" }
variable "not-found-response-path" { default = "/404.html" }
variable "default-ttl" { default = 86400 }
variable "max-ttl" { default = 31536000 }
