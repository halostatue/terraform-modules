resource "aws_s3_bucket" "bucket" {
  bucket = local.bucket-name

  tags = merge(local.tags, { Purpose = "redirect-site bucket for redirects to ${var.target}" })

  lifecycle {
    prevent_destroy = true
  }
}
