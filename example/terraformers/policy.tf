data "aws_iam_policy_document" "terraformers" {
  policy_id = "TerraformerGroupPolicy"

  statement = {
    sid       = "Route53Permissions"
    effect    = "Allow"
    actions   = ["route53:*"]
    resources = ["arn:aws:route53:::*"]
  }

  statement = {
    sid       = "S3Permissions"
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::*"]
  }

  statement = {
    sid     = "CloudFrontPermissions"
    effect  = "Allow"
    actions = ["cloudfront:*"]

    resources = [
      "*",
      "arn:aws:cloudfront:::*",
      "arn:aws:cloudfront::737111750993:*",
      "arn:aws:cloudfront::737111750993:distribution/*",
    ]
  }

  statement = {
    sid    = "IAMPolicyMinimum"
    effect = "Allow"

    resources = [
      "arn:aws:iam::737111750993:user/*",
      "arn:aws:iam::737111750993:group/*",
      "arn:aws:iam::737111750993:role/*",
      "arn:aws:iam::737111750993:policy/*",
    ]

    actions = [
      "iam:AddRoleToInstanceProfile",
      "iam:AddUserToGroup",
      "iam:AttachGroupPolicy",
      "iam:AttachRolePolicy",
      "iam:AttachUserPolicy",
      "iam:CreateAccessKey",
      "iam:CreateGroup",
      "iam:CreateInstanceProfile",
      "iam:CreatePolicy",
      "iam:CreatePolicyVersion",
      "iam:CreateRole",
      "iam:CreateUser",
      "iam:DeleteAccessKey",
      "iam:DeleteGroup",
      "iam:DeleteGroupPolicy",
      "iam:DeleteInstanceProfile",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:DeleteServerCertificate",
      "iam:DeleteSigningCertificate",
      "iam:DeleteUser",
      "iam:DeleteUserPolicy",
      "iam:DetachGroupPolicy",
      "iam:DetachRolePolicy",
      "iam:DetachUserPolicy",
      "iam:GetAccessKeyLastUsed",
      "iam:GetContextKeysForCustomPolicy",
      "iam:GetContextKeysForPrincipalPolicy",
      "iam:GetGroup",
      "iam:GetGroupPolicy",
      "iam:GetInstanceProfile",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:GetUser",
      "iam:GetUserPolicy",
      "iam:ListAccessKeys",
      "iam:ListAttachedGroupPolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListAttachedUserPolicies",
      "iam:ListEntitiesForPolicy",
      "iam:ListGroupPolicies",
      "iam:ListGroups",
      "iam:ListGroupsForUser",
      "iam:ListInstanceProfiles",
      "iam:ListInstanceProfilesForRole",
      "iam:ListPolicies",
      "iam:ListPoliciesGrantingServiceAccess",
      "iam:ListPolicyVersions",
      "iam:ListRolePolicies",
      "iam:ListRoles",
      "iam:ListServerCertificates",
      "iam:ListSigningCertificates",
      "iam:ListUserPolicies",
      "iam:ListUsers",
      "iam:PutGroupPolicy",
      "iam:PutRolePolicy",
      "iam:PutUserPolicy",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:RemoveUserFromGroup",
      "iam:SetDefaultPolicyVersion",
      "iam:UpdateAccessKey",
      "iam:UpdateAssumeRolePolicy",
      "iam:UpdateGroup",
      "iam:UpdateServerCertificate",
      "iam:UpdateSigningCertificate",
      "iam:UpdateUser",
      "iam:UploadServerCertificate",
      "iam:UploadSigningCertificate",
    ]
  }
}
