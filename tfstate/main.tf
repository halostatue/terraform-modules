variable "region" { default = "" }
variable "profile" { default = "" }

variable "tfstate-prefix" {
  description = "The prefix to use for storing the tfstate"
  default = "config/"
}
variable "user" {
  description = "Optional user to be created to manage the tfstate bucket."
  default = ""
}
variable "bucket" {
  description = "Optional tfstate bucket to create."
  default = ""
}
variable "prefix" {
  description = "Prefix for bucket name and user if user/bucket are empty."
  default = ""
}

provider "aws" {
  region = "${var.region}"
  profile = "${var.profile}"
}

resource "aws_iam_user" "terraform" {
  name = "${coalesce("${var.user}", "${var.prefix}-terraform")}"
  path = "/"
}

resource "aws_s3_bucket" "terraform-state-bucket" {
  bucket = "${coalesce("${var.bucket}", "${var.prefix}-tfstate")}"
  acl = "private"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    prefix = "${var.tfstate-prefix}"
    enabled = true
    noncurrent_version_expiration {
      days = 90
    }
  }
}

data "aws_iam_policy_document" "terraform-policy" {
  statement = {
    actions = [ "s3:*" ]
    resources = [
      "${aws_s3_bucket.terraform-state-bucket.arn}",
      "${aws_s3_bucket.terraform-state-bucket.arn}/*"
    ]
  }
}

resource "aws_iam_user_policy" "terraform-policy" {
  name = "FullAccess-${coalesce("${var.bucket}", "${var.prefix}-tfstate")}"
  user = "${aws_iam_user.terraform.name}"
  policy = "${data.aws_iam_policy_document.terraform-policy.json}"
}

output "terraform-config-command" {
  value = <<EOF

terraform remote config \
  -backend=s3 \
  -backend-config="bucket=${aws_s3_bucket.terraform-state-bucket.id}" \
  -backend-config="key=${var.tfstate-prefix}terraform.tfstate" \
  -backend-config="region=${aws_s3_bucket.terraform-state-bucket.region}"
EOF
}
