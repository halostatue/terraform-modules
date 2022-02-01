terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

variable "aws-region" {
  description = "The (optional) name of the AWS Region to use."

  type = string
  # nullable = false

  validation {
    condition     = length(var.aws-region) > 4 && can(regex("^[a-z]+-[a-z]+-[0-9]+", var.aws-region))
    error_message = "The aws-region must not be blank and must match the usual format."
  }
}

variable "aws-profile" {
  description = "The (optional) name of the AWS CLI profile name to use."

  type = string
  # nullable = false

  validation {
    condition     = length(var.aws-profile) > 1 && can(regex("^[-a-z0-9_]+$", var.aws-profile))
    error_message = "The aws-profile must not be blank and must match the usual format."
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

provider "aws" {
  region  = var.aws-region
  profile = var.aws-profile
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

  lifecycle {
    prevent_destroy = true
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
