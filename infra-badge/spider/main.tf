terraform {
  required_version = "~>0.12.5"
}

provider "aws" {
  region  = "eu-west-2"
  version = "~> 2.31"
}

module "label" {
  source     = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=tags/0.4.0"
  namespace  = "cormac"
  stage      = terraform.workspace
  name       = "spider-infra-badge"
  attributes = []
  delimiter  = "-"
}

// s3
resource "aws_s3_bucket" "application_bucket" {
  bucket = "${module.label.id}-application-bucket"
  acl    = "private"
}

resource "aws_s3_bucket_metric" "example-entire-bucket" {
  bucket = aws_s3_bucket.application_bucket.bucket
  name   = "EntireBucket"
}

resource "aws_s3_bucket" "static_bucket" {
  bucket = "${module.label.id}-static-bucket"
  acl    = "private"
}

// iam policy -> group -> user
data "aws_iam_policy_document" "application_bucket_get_acess" {
  statement {
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.application_bucket.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "application_bucket_get_acess" {
  policy = data.aws_iam_policy_document.application_bucket_get_acess.json
}

resource "aws_iam_group" "application_permistions" {
  name = "${module.label.id}-application-permistions"

}

resource "aws_iam_group_policy_attachment" "application_bucket_get_acess" {
  group      = aws_iam_group.application_permistions.name
  policy_arn = aws_iam_policy.application_bucket_get_acess.arn
}

resource "aws_iam_user" "appliation" {
  name = module.label.id
  path = "/system/"
}

resource "aws_iam_group_membership" "application" {
  name  = module.label.id
  group = aws_iam_group.application_permistions.name
  users = [
    aws_iam_user.appliation.name
  ]
}

//system user creds
resource "aws_iam_access_key" "applcation" {
  user = aws_iam_user.appliation.name
}

output "AWS_ACCESS_KEY_ID" {
  value = aws_iam_access_key.applcation.id
}

output "AWS_SECRET_ACCESS_KEY" {
  value = aws_iam_access_key.applcation.secret
}

output "bucket_names" {
  value = [
    aws_s3_bucket.application_bucket.bucket,
    aws_s3_bucket.static_bucket.bucket
  ]
}