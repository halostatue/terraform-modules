resource "aws_iam_user" "terraformer" {
  name = "halostatue-infrastructure"
}

resource "aws_iam_access_key" "terraformer" {
  user = "${aws_iam_user.terraformer.name}"
}

output "terraformer" {
  value = "${aws_iam_user.terraformer.name}"
}

output "terraformer_access_key" {
  sensitive = true

  value = {
    aws_access_key_id     = "${aws_iam_access_key.terraformer.id}"
    aws_secret_access_key = "${aws_iam_access_key.terraformer.secret}"
  }
}
