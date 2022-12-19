variable "domain-name" {
  description = "The main domain name for the certificate. Wildcard certificates can be specified."

  type = string
}

variable "alternate-names" {
  description = "Alternate names for the certificate (optional)."

  type    = list(string)
  default = []
}

variable "validation-method" {
  description = "The validation method for the certificate. Must be DNS or EMAIL."

  type = string

  validation {
    condition     = var.validation-method == "DNS" || var.validation-method == "EMAIL"
    error_message = "The validation-method must be DNS or EMAIL."
  }
}

variable "certificate-transparency-logging-preference" {
  description = "The logging preference for certificate transparency. Defaults to ENABLED."

  type    = string
  default = ""

  validation {
    condition = (
      var.certificate-transparency-logging-preference == "" ||
      var.certificate-transparency-logging-preference == "DISABLED" ||
      var.certificate-transparency-logging-preference == "ENABLED"
    )
    error_message = "The certificate-transparency-logging-preference must be omitted, DISABLED, or ENABLED."
  }
}
