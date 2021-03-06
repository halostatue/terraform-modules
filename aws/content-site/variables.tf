# AWS Configuration Variables
variable "aws-region" {
  description = "The (optional) name of the AWS Region to use."
  default     = ""
}

variable "aws-profile" {
  description = "The (optional) name of the AWS CLI profile name to use."
  default     = ""
}

variable "bucket" {
  description = "The (optional) name for the S3 bucket to create for deployment."
  default     = ""
}

variable "content-key-base" {
  description = "The base value of the content key used to prevent duplicate content penalties from being applied by Google."
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
  type        = "list"
  description = "The (optional) aliases of the domain to provide."
  default     = []
}

variable "acm-certificate-arn" {
  description = "The ACM Certificate ARN."
  default     = ""
}

variable "default-ttl" {
  description = "The default TTL for the distribution (300, 3600, 86400)."
  default     = 86400                                                      // 1 Day
}

variable "max-ttl" {
  description = "The maximum TTL for the distribution (1200, 86400, 31536000)."
  default     = 31536000                                                        // 365 Days
}
