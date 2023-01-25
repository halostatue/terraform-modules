locals {
  bucket-name    = replace(coalesce(var.bucket, var.target), ".", "-")
  domain-aliases = distinct(compact(var.domain-aliases))
}
