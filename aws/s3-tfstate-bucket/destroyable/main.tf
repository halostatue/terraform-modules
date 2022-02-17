terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
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

resource "aws_s3_bucket" "terraform" {
  bucket = var.bucket
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "tfstate"
    prefix  = ""
    enabled = true

    noncurrent_version_expiration {
      days = var.expiration-days
    }
  }

  tags = {
    Purpose         = "Terraform state bucket"
    Terraform       = true
    TerraformModule = "github.com/halostatue/terraform-modules//aws/s3-tfstate-bucket@v3.0.0"
  }
}

resource "aws_iam_user_policy" "terraform" {
  name = "TerraformAccess-${var.bucket}"
  user = var.user
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:*"]
        Resource = [
          aws_s3_bucket.terraform.arn,
          "${aws_s3_bucket.terraform.arn}/*",
        ]
      }
    ]
  })
}

output "id" {
  value = aws_s3_bucket.terraform.id
}
