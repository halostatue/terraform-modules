variable "region" { default = "" }
variable "profile" { default = "" }

variable "bucket" {
  description = "The S3 bucket to create for website deployment"
}

variable "random-id-domain-keeper" {
  description = "The value to use as the keeper for the duplicate-content-penalty-secret domain."
  default = ""
}

variable "domain" {
  description = "The name of the domain to provision."
}

variable "routing-rules" {
  description = "Custom routing rules for the distribution."
  default = ""
}

variable "not-found-response-path" {
  description = "The path to the object returned when the site cannot be found."
  default = "/404.html"
}

variable "domain-aliases" {
  type = "list"
  description = "The aliases of the domain to provide."
}

variable "acm-certificate-arn" {
  description = "The ACM Certificate ARN"
  default = ""
}

variable "default-ttl" {
  description = "The default TTL for the distribution (300, 3600, 86400)."
  default = 86400 // 1 Day
}

variable "max-ttl" {
  description = "The maximum TTL for the distribution (1200, 86400, 31536000)."
  default = 31536000 // 365 Days
}
