variable "zone-id" {
  type = string

  description = "The domain zone ID for the disallowed email domain."
}

variable "name" {
  type = string

  description = "The domain name to be marked as disallowing email."
}

variable "include-spf" {
  type    = bool
  default = true

  description = "The SPF record should be included. Set to no if the domain has other TXT records."
}

variable "subdomains-send-email" {
  type    = bool
  default = false

  description = "Adjust the DMARC record because subdomains of this domain send email."
}

variable "dmarc-rua" {
  type    = list(string)
  default = []

  description = "The list of propely formatted DMARC rua email addresses"
}

variable "dmarc-ruf" {
  type    = list(string)
  default = []

  description = "The list of propely formatted DMARC ruf email addresses"
}

variable "is-subdomain" {
  type    = bool
  default = false

  description = "Set to true if this is a subdomain."
}

variable "ttl" {
  type    = number
  default = 86400

  description = "The default TTL for these records."
}
