provider "aws" {
  region  = "eu-west-2"
  version = "~> 2.23"
}

module "label" {
  source    = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=master"
  namespace = "cormac"
  //  stage      = "dev"
  name = "aws-config-test"
  //  attributes = ["test"]
  delimiter = "-"

  tags = {
    "owner" = "cormac",
  }
}

resource "aws_config_configuration_recorder_status" "foo" {
  name       = aws_config_configuration_recorder.foo.name
  is_enabled = true
  depends_on = ["aws_config_delivery_channel.foo"]
}

resource "aws_iam_role_policy_attachment" "a" {
  role       = aws_iam_role.r.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

resource "aws_s3_bucket" "b" {
  bucket = "${module.label.id}-awsconfig"
  tags   = module.label.tags

  force_destroy = true
}

resource "aws_sns_topic" "aws-config-failures" {
  name = "aws-config-failures"
}

resource "aws_config_delivery_channel" "foo" {
  name           = module.label.id
  s3_bucket_name = aws_s3_bucket.b.bucket
  sns_topic_arn  = aws_sns_topic.aws-config-failures.arn
}

resource "aws_config_configuration_recorder" "foo" {
  name     = module.label.id
  role_arn = aws_iam_role.r.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_iam_role" "r" {
  name = module.label.id
  tags = module.label.tags

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "p" {
  name = module.label.id
  role = aws_iam_role.r.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.b.arn}",
        "${aws_s3_bucket.b.arn}/*"
      ]
    },
    {
      "Action": [
       "SNS:Publish"
      ],
      "Effect": "Allow",
      "Resource": [
       "${aws_sns_topic.aws-config-failures.arn}"
      ]
    }
  ]
}
POLICY
}


resource "aws_config_config_rule" "two-factor-for-console-access" {
  name = "two-factor-if-using-console"
  tags = module.label.tags

  source {
    owner             = "AWS"
    source_identifier = "MFA_ENABLED_FOR_IAM_CONSOLE_ACCESS"
  }

  depends_on = ["aws_config_configuration_recorder.foo"]
}

resource "aws_config_config_rule" "vpc" {
  name = "block-ssh"
  tags = module.label.tags

  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }

  depends_on = ["aws_config_configuration_recorder.foo"]
}
