locals {
  fqdn           = join(".", compact([var.site-name, var.domain-name]))
  bucket-name    = replace(coalesce(var.bucket, local.fqdn), ".", "-")
  domain-aliases = distinct(compact(flatten(concat([local.fqdn], var.domain-aliases))))

  create-domain = (
    (
      var.dns-zone-id == null || var.site-name == null
    ) ? 0 : (length(var.dns-zone-id) > 0 && length(var.site-name) > 0) ? 1 : 0
  )

  publishers-count = (var.create-publisher == true ? 1 : 0) + length(var.additional-publishers)

  publisher_key_versions = var.create-publisher == false ? {} : (
    var.publisher-key-versions == null ? { "v1" = "Active" } :
    merge([for kv in var.publisher-key-versions : { (kv.name) = kv.status }]...)
  )
}
