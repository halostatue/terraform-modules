# AWS Configuration Variables
variable "bucket" {
  description = "The (optional) name for the S3 bucket to create for deployment."
  default     = ""
}

variable "domain" {
  description = "The name of the domain to provision."
}

variable "routing-rules" {
  description = "Custom routing rules for the distribution."
  default     = ""
}

variable "not-found-response-path" {
  description = "The path to the object returned when the site cannot be found."
  default     = "/404.html"
}

variable "domain-aliases" {
  type        = list(any)
  description = "The (optional) aliases of the domain to provide."
  default     = []
}

variable "publisher" {
  description = "The name/id of the publisher user."
}

variable "target" {
  description = "The destination address for the redirect, without protocol."
}

variable "content-key" {
  description = "The content key used to prevent duplicate content penalties from being applied by Google."
}

variable "acm-certificate-arn" {
  description = "The ACM Certificate ARN."
  default     = ""
}

variable "default-ttl" {
  description = "The default TTL for the distribution (300, 3600, 86400)."
  default     = 86400 // 1 Day
}

variable "max-ttl" {
  description = "The maximum TTL for the distribution (1200, 86400, 31536000)."
  default     = 31536000 // 365 Days
}
