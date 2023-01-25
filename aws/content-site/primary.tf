resource "aws_s3_bucket" "bucket" {
  bucket = local.bucket-name

  tags = merge(local.tags, { Purpose = "content-site content bucket for ${local.fqdn}" })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "${local.bucket-name}-log"

  tags = merge(local.tags, { Purpose = "content-site log bucket for ${local.fqdn}" })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_user" "publisher" {
  count = var.create-publisher == false ? 0 : 1

  name = coalesce(var.publisher-name, "${local.bucket-name}-publisher")

  tags = merge(local.tags, { Purpose = "content-site publisher for ${local.fqdn}" })

  lifecycle {
    prevent_destroy = true
  }
}
