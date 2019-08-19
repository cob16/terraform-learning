//password-policy
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 12
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
}

//s3 public acess
resource "aws_s3_account_public_access_block" "secure_s3_public_acls" {
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

# groups

resource "aws_iam_group" "developer" {
  name = "developer"
}

resource "aws_iam_group" "admin" {
  name = "admin"
}

# conditions
locals {
  condition_if_multi_factor_auth_enabled = {
    test     = "Bool"
    variable = "aws:MultiFactorAuthPresent"

    values = [
      "true",
    ]
  }

  condition_restrict_region = {
    test     = "StringEquals"
    variable = "aws:RequestedRegion"

    values = [
      "eu-west-2",
    ]
  }
}

# get the curerent account arns ids and username for later
data "aws_caller_identity" "current" {}

# developer policys

data "aws_iam_policy_document" "manage_personal_mfa" {
  # based off https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa_configure-api-require.html#MFAProtectedAPI-user-mfa
  statement {
    actions = [
      "iam:ListMFADevices",
    ]

    resources = [
      "arn:aws:iam::*:mfa/*",
      "arn:aws:iam::*:user/$${aws:username}", ## $$ is used here to escape terrfarom parsing this aws var
    ]
  }

  statement {
    actions = [
      "iam:CreateVirtualMFADevice",
      "iam:DeleteVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:ResyncMFADevice",
    ]

    resources = [
      "arn:aws:iam::*:mfa/*",
      "arn:aws:iam::*:user/$${aws:username}", ## $$ is used here to escape terrfarom parsing this aws var
    ]
  }

  statement {
    actions = [
      "iam:DeactivateMFADevice",
    ]

    resources = [
      "arn:aws:iam::*:mfa/*",
      "arn:aws:iam::*:user/$${aws:username}", ## $$ is used here to escape terrfarom parsing this aws var
    ]

    condition = [
      "${local.condition_if_multi_factor_auth_enabled}",
    ]
  }
}

resource "aws_iam_policy" "manage_personal_mfa" {
  name   = "manage_personal_mfa"
  path   = "/"
  policy = "${data.aws_iam_policy_document.manage_personal_mfa.json}"
}

data "aws_iam_policy_document" "developers_manage_personal_keys" {
  statement {
    sid = "ManageSSHKeys"

    actions = [
      "iam:CreateAccessKey",
      "iam:DeleteAccessKey",
      "iam:UpdateAccessKey",
    ]

    resources = [
      "arn:aws:iam::*:user/$${aws:username}", ## $$ is used here to escape terrfarom parsing this aws var
    ]
  }
}

resource "aws_iam_policy" "developers_manage_personal_keys" {
  name   = "developers_manage_personal_keys"
  path   = "/"
  policy = "${data.aws_iam_policy_document.developers_manage_personal_keys.json}"
}

data "aws_iam_policy_document" "allow_S3_mfa" {
  statement {
    sid = "allowS3Mfa"

    actions = [
      "s3:*",
    ]

    resources = [
      "*",
    ]

    condition = [
      "${local.condition_if_multi_factor_auth_enabled}",
    ]
  }

  statement {
    sid    = "ForceS3Region"
    effect = "Deny"

    actions = [
      "s3:CreateBucket",
    ]

    resources = [
      "*",
    ]

    condition = [
      {
        test     = "StringNotEquals"
        variable = "aws:RequestedRegion"

        values = [
          "eu-west-2",
        ]
      },
    ]
  }

  statement {
    sid    = "DenyStateBucket" ## comment this statement out if not using state bucket
    effect = "Deny"

    actions = [
      "s3:*",
    ]

    resources = [
      "arn:aws:s3:::ceb-terraform-remote-state-storage-s3/*",
      "arn:aws:s3:::ceb-terraform-remote-state-storage-s3",
    ]
  }
}

resource "aws_iam_policy" "allow_S3_mfa" {
  name   = "allow_S3_mfa"
  path   = "/"
  policy = "${data.aws_iam_policy_document.allow_S3_mfa.json}"
}

data "aws_iam_policy_document" "allow_ec2_if_mfa_enabled" {
  statement {
    sid = "AllowEC2General"

    actions = [
      "ec2:*",
      "elasticloadbalancing:*",
      "cloudwatch:*",
      "autoscaling:*",
    ]

    resources = [
      "*",
    ]

    condition = [
      "${local.condition_if_multi_factor_auth_enabled}",
      "${local.condition_restrict_region}",
    ]
  }

  statement {
    sid = "AllowEC2GeneralLinkedRoles"

    actions = [
      "iam:CreateServiceLinkedRole",
    ]

    resources = [
      "*",
    ]

    condition = [
      "${local.condition_if_multi_factor_auth_enabled}",
      "${local.condition_restrict_region}",
      {
        test     = "StringEquals"
        variable = "iam:AWSServiceName"

        values = [
          "autoscaling.amazonaws.com",
          "ec2scheduled.amazonaws.com",
          "elasticloadbalancing.amazonaws.com",
          "spot.amazonaws.com",
          "spotfleet.amazonaws.com",
          "transitgateway.amazonaws.com",
        ]
      },
    ]
  }
}

resource "aws_iam_policy" "allow_ec2_if_mfa_enabled" {
  name   = "allow_ec2_if_mfa_enabled"
  path   = "/"
  policy = "${data.aws_iam_policy_document.allow_ec2_if_mfa_enabled.json}"
}

# admin policys

data "aws_iam_policy_document" "allow_admin_if_mfa" {
  statement {
    sid = "RequireAdminMFA"

    actions = [
      "*",
    ]

    resources = [
      "*",
    ]

    condition = [
      "${local.condition_if_multi_factor_auth_enabled}",
    ]
  }
}

resource "aws_iam_policy" "allow_admin_if_mfa" {
  name   = "allow_admin_if_mfa"
  path   = "/"
  policy = "${data.aws_iam_policy_document.allow_admin_if_mfa.json}"
}

data "aws_iam_policy_document" "assume_role_to_admin" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/admin",
    ]

    condition = [
      "${local.condition_if_multi_factor_auth_enabled}",
    ]
  }
}

resource "aws_iam_policy" "assume_role_to_admin" {
  name   = "assume_role_to_admin"
  path   = "/"
  policy = "${data.aws_iam_policy_document.assume_role_to_admin.json}"
}

# admin assume role
data "aws_iam_policy_document" "admin_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_iam_role" "admin_assume_role" {
  name               = "admin"
  assume_role_policy = "${data.aws_iam_policy_document.admin_assume_role_policy.json}"
}

resource "aws_iam_policy_attachment" "admin_assume_role_policy" {
  name       = "admin_assume_role_policy"
  roles      = ["${aws_iam_role.admin_assume_role.name}"]
  policy_arn = "${aws_iam_policy.allow_admin_if_mfa.arn}"
}

# developer group policy-attachments
resource "aws_iam_group_policy_attachment" "developers_iam_read_only_access" {
  group      = "${aws_iam_group.developer.name}"
  policy_arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
}

# only neded for codeDeploy
# resource "aws_iam_group_policy_attachment" "IAMSelfManageServiceSpecificCredentials" { 
#   group      = "${aws_iam_group.developer.name}"
#   policy_arn = "arn:aws:iam::aws:policy/IAMSelfManageServiceSpecificCredentials"
# }

resource "aws_iam_group_policy_attachment" "developers_iam_User_change_password" {
  group      = "${aws_iam_group.developer.name}"
  policy_arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"
}

resource "aws_iam_group_policy_attachment" "developers_iam_user_ssh_keys" {
  group      = "${aws_iam_group.developer.name}"
  policy_arn = "arn:aws:iam::aws:policy/IAMUserSSHKeys"
}

resource "aws_iam_group_policy_attachment" "developers_manage_personal_keys" {
  group      = "${aws_iam_group.developer.name}"
  policy_arn = "${aws_iam_policy.developers_manage_personal_keys.arn}"
}

resource "aws_iam_group_policy_attachment" "developers_manage_personal_mfa" {
  group      = "${aws_iam_group.developer.name}"
  policy_arn = "${aws_iam_policy.manage_personal_mfa.arn}"
}

resource "aws_iam_group_policy_attachment" "developers_allow_s3_mfa" {
  group      = "${aws_iam_group.developer.name}"
  policy_arn = "${aws_iam_policy.allow_S3_mfa.arn}"
}

resource "aws_iam_group_policy_attachment" "developers_allow_ec2_if_mfa_enabled" {
  group      = "${aws_iam_group.developer.name}"
  policy_arn = "${aws_iam_policy.allow_ec2_if_mfa_enabled.arn}"
}

# admin group policy-attachments

resource "aws_iam_group_policy_attachment" "assume_role_to_admin" {
  group      = "${aws_iam_group.admin.name}"
  policy_arn = "${aws_iam_policy.assume_role_to_admin.arn}"
}
