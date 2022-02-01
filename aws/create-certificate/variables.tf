# AWS Configuration Variables
variable "aws-region" {
  description = "The name of the AWS Region to use."

  type = string
  # nullable = false

  validation {
    condition     = length(var.aws-region) > 4 && can(regex("^[a-z]+-[a-z]+-[0-9]+", var.aws-region))
    error_message = "The aws-region must not be blank and must match the usual format."
  }
}

variable "aws-profile" {
  description = "The name of the AWS CLI profile name to use."

  type = string
  # nullable = false

  validation {
    condition     = length(var.aws-profile) > 1 && can(regex("^[-a-z0-9_]+$", var.aws-profile))
    error_message = "The aws-profile must not be blank and must match the usual format."
  }
}

variable "domain-name" {
  description = "The main domain name for the certificate. Wildcard certificates can be specified."

  type = string
  # nullable = false
}

variable "alternate-names" {
  description = "Alternate names for the certificate (optional)."

  type    = list(string)
  default = []
  # nullable = true
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
