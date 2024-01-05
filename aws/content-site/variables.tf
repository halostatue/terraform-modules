# Required
variable "domain-name" {
  description = "The domain name of the site to be provisioned. The FQDN for the site is `site-name.domain-name`."

  type = string
}

# Optional with fallbacks
variable "site-name" {
  description = "The name of the site to be provisioned. If omitted, the bare domain name is the target and a DNS record will not be created automatically."

  default = null
  type    = string
}

variable "bucket" {
  description = "The S3 bucket to create for website deployment; if not provided, defaults to a value based on the FQDN."

  default = ""
  type    = string
}

variable "content-key-base" {
  description = "The value to use as the keeper for the content-key. If not provided, the computed FQDN is used."

  default = ""
  type    = string
}

variable "routing-rules" {
  description = "A JSON-encoded array of custom routing rules for the distribution. https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-websiteconfiguration-routingrules.html"

  default = null
  type    = string
}

variable "domain-aliases" {
  description = "The aliases of the domain to provide; if not provided, defaults to [var.domain]"

  default = []
  type    = list(string)
}

# Optional with sensible defaults
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

variable "log-expiration-days" {
  description = "The number of days that logs will be kept for the content site bucket"

  default = 90
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

variable "create-publisher" {
  description = "Create the publisher; set to false to prevent creating a publisher user and access key"

  default = true
  type    = bool
}

variable "publisher-name" {
  description = "The name of the publisher; if unset, defaults to BUCKET-site-publisher"

  default = ""
  type    = string
}

variable "publisher-key-versions" {
  description = "The key versions for the publisher. If omitted, a v1 key is created"

  default = null
  type    = list(object({ name = string, status = string }))

  validation {
    condition = var.publisher-key-versions == null || (
      length(coalesce(var.publisher-key-versions, [])) > 0 &&
      length(coalesce(var.publisher-key-versions, [])) < 3
    )
    error_message = "The value publisher-key-versions must be omitted or an array of one or two entries."
  }

  validation {
    condition = var.publisher-key-versions == null || (
      length(
        [
          for kv in coalesce(var.publisher-key-versions, []) : kv if(
            kv.status == "Active" || kv.status == "Inactive"
          )
      ]) ==
      length(coalesce(var.publisher-key-versions, []))
    )
    error_message = "The value publisher-key-versions must have status values of Active or Inactive only."
  }
}

variable "additional-publishers" {
  description = "Additional publisher names to which to add to the publisher IAM group."

  default = []
  type    = set(string)
}

variable "additional-publisher-groups" {
  description = "Additional IAM groups to which the publisher policy will be attached."

  default = []
  type    = set(string)
}

variable "create-dns-record" {
  description = "Create the DNS A record for the domain, if provided."

  default = false
  type    = bool
}

variable "dns-zone-id" {
  description = "The AWS Route 53 Zone ID for creating the DNS record. If dns-zone-id or site-name are unspecified, a DNS record will not be created."

  default = null
  type    = string
}

variable "block-public-policy" {
  description = "Whether public policies should be blocked."

  default = true
  type    = bool
}

variable "protocol-policy" {
  description = "The viewer protocol policy to use; defaults to redirect-to-https."

  default = "redirect-to-https"
  type    = string
}

variable "tags" {
  description = "Default tags for the created resources."

  default = {}
  type    = map(string)
}

variable "cors-rules" {
  description = "CORS rules to be applied; always allows GET and HEAD requests regardless of origin or header if enabled"

  default  = null
  nullable = true
  type = set(object({
    allowed-origins = set(string)
    allowed-headers = optional(set(string), ["*"])
    allowed-methods = optional(set(string), ["GET", "HEAD", "PUT", "POST"])
    expose-headers = optional(set(string), [
      "Authorization", "Content-Length", "ETag", "x-amz-acl", "x-amz-id-2", "x-amz-request-id",
      "x-amz-server-side-encryption"
    ])
    max-age-seconds = optional(number, 240)
  }))
}
