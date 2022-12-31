variable "domain-name" {
  description = "The primary domain name for the certificate. Wildcard certificates may be specified."

  type = string
}

variable "zone-id" {
  description = "The default Route53 zone ID for DNS validation of the certificate being issued."

  type = string
}

variable "alternatives" {
  description = "A map of domains to objects containing an optional Route53 zone ID for creating validation records."

  default = {}
  type    = map(object({ zone-id = optional(string) }))
}

variable "certificate-transparency-logging-preference" {
  description = "The logging preference for certificate transparency. Defaults to ENABLED."

  default = "ENABLED"
  type    = string

  validation {
    condition = (
      var.certificate-transparency-logging-preference == "DISABLED" ||
      var.certificate-transparency-logging-preference == "ENABLED"
    )
    error_message = "The certificate-transparency-logging-preference must be omitted, DISABLED, or ENABLED."
  }
}

variable "dns-record-ttl" {
  description = "Time to live for the DNS validation records. Defaults to ten minutes."

  default = 600
  type    = number
}

variable "key-algorithm" {
  description = "The key algorithm for this certficiate. Defaults to RSA_2048 (RSA 2048 bit), but supports EC_prime256v1 (ECDSA 256 bit) and EC_secp384r1 (ECDSA 384 bit)."

  default = "RSA_2048"
  type    = string

  validation {
    condition = (
      var.key-algorithm == "RSA_2048" ||
      var.key-algorithm == "EC_prime256v1" ||
      var.key-algorithm == "EC_secp384r1"
    )

    error_message = "The key-algorithm must be one of RSA_2048, EC_prime256v1, or EC_secp384r1."
  }
}

variable "tags" {
  description = "Default tags for the created resources."

  default = {}
  type    = map(string)
}
