variable "aws-region" {
  description = "The (optional) name of the AWS Region to use."
  default     = ""
}

variable "aws-profile" {
  description = "The (optional) name of the AWS CLI profile name to use."
  default     = ""
}

variable "bucket" {
  description = "The bucket to create for storing terraform state."
}

variable "user" {
  description = "The user for which permissions will be granted on this bucket."
}

variable "expiration-days" {
  description = "The number of days until the non-current version expires."
  default     = 90
}

provider "aws" {
  region  = "${var.aws-region}"
  profile = "${var.aws-profile}"
}

resource "aws_s3_bucket" "terraform" {
  bucket = "${var.bucket}"
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "tfstate"
    prefix  = ""
    enabled = true

    noncurrent_version_expiration {
      days = "${var.expiration-days}"
    }
  }
}

data "aws_iam_policy_document" "terraform" {
  statement = {
    actions = ["s3:*"]

    resources = [
      "${aws_s3_bucket.terraform.arn}",
      "${aws_s3_bucket.terraform.arn}/*",
    ]
  }
}

resource "aws_iam_user_policy" "terraform" {
  name   = "TerraformAccess-${var.bucket}"
  user   = "${var.user}"
  policy = "${data.aws_iam_policy_document.terraform.json}"
}

output "id" {
  value = "${aws_s3_bucket.terraform.id}"
}
