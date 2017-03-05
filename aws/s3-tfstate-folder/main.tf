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

variable "folder" {
  description = "The name to use for this tfstate folder."
}

provider "aws" {
  region  = "${var.aws-region}"
  profile = "${var.aws-profile}"
}

data "template_file" "command" {
  vars {
    bucket  = "${var.bucket}"
    key     = "${var.folder}/terraform.tfstate"
    region  = "${var.aws-region}"
    profile = "${var.aws-profile}"
  }

  template = <<EOF

terraform remote config \
  -backend=s3 \
  -backend-config="bucket=$${bucket}" \
  -backend-config="key=$${key}" \
  -backend-config="region=$${region}" \
  -backend-config="profile=$${profile}"
EOF
}

data "template_file" "config" {
  vars {
    bucket  = "${var.bucket}"
    folder  = "${var.folder}"
    key     = "${var.folder}/terraform.tfstate"
    region  = "${var.aws-region}"
    profile = "${var.aws-profile}"
  }

  template = <<EOF

data "terraform_remote_state" "$${folder}" {
  backend = "s3"

  config {
    bucket = "$${bucket}"
    key = "$${key}"
    region = "$${region}"
    profile = "$${profile}"
  }
}
EOF
}

output "command" {
  value = "${data.template_file.command.rendered}"
}

output "config" {
  value = "${data.template_file.config.rendered}"
}
