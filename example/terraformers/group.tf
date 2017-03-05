resource "aws_iam_group" "terraformers" {
  name = "terraformers"
}

resource "aws_iam_group_policy" "terraformers" {
  name   = "terraformers_policy"
  group  = "${aws_iam_group.terraformers.id}"
  policy = "${data.aws_iam_policy_document.terraformers.json}"
}

resource "aws_iam_group_membership" "terraformers" {
  name  = "terraformers_group_membership"
  group = "${aws_iam_group.terraformers.name}"

  users = [
    "${aws_iam_user.terraformer.name}",
  ]
}
