# Required variables
variable "target" {
  description = "The destination address for the redirect, without protocol."

  type = string
}

variable "domain-aliases" {
  description = "The domain names that will redirect to var.target."

  type = list(string)
}

# Optional with fallbacks
variable "bucket" {
  description = "The S3 bucket to create for redirect; if not provided, defaults to a value based on the target"

  default = ""
  type    = string
}

# Optional variables with sensible defaults
variable "default-ttl" {
  description = "The default TTL in seconds for the distribution (300, 3600, 86400)"

  default = 86400 // 1 Day
  type    = number
}

variable "max-ttl" {
  description = "The maximum TTL in seconds for the distribution (1200, 86400, 31536000)"

  default = 31536000 // 365 Days
  type    = number
}

variable "error-ttl" {
  description = "The TTL in seconds that errors will be returned even if the document is put into place (300, 1800, 7200)."

  default = 1800
  type    = number
}

variable "index-document" {
  description = "The S3 key for the document to return from the bucket when requesting an index."

  default = "index.html"
  type    = string
}

variable "error-document" {
  description = "The S3 key for the document to return from the bucket when a document cannot be found."

  default = "404.html"
  type    = string
}

# Optional variables that change how certain features function
variable "acm-certificate-arn" {
  description = "The ACM Certificate ARN for this site; if not provided, uses the CloudFront default certificate"

  default = ""
  type    = string
}

variable "target-protocol" {
  description = "The protocol to use on redirect. If 'https', always forces upgrade to https."

  default = "https"
  type    = string

  validation {
    condition     = var.target-protocol == "https" || var.target-protocol == "http"
    error_message = "The value of target-protocol can only be http or https."
  }
}

variable "block-public-policy" {
  description = "Whether public policies should be blocked."

  default = true
  type    = bool
}

variable "protocol-policy" {
  description = "The viewer protocol policy to use; if target-protocol is https, this will always be redirect-to-https."

  default = "allow-all"
  type    = string

  validation {
    condition     = var.protocol-policy == "allow-all" || var.protocol-policy == "https-only" || var.protocol-policy == "redirect-to-https"
    error_message = "The value of protocol-policy can only be allow-all, https-only, or redirect-to-https."
  }
}

variable "publishers" {
  description = "The names or IDs of publisher users"

  default = []
  type    = list(string)
}

variable "content-key" {
  description = "The content key used to prevent duplicate content penalties from being applied by Google."

  default = ""
  type    = string
}
