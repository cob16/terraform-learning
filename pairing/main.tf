terraform {
  required_version = "~>0.12.20"
}

provider "aws" {
  region  = "eu-west-2"
  version = "~> 2.46"
}


module "label" {
  source     = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=tags/0.4.0"
  namespace  = "cormac"
  stage      = terraform.workspace
  name       = "paring"
  attributes = ["interview"]
  delimiter  = "-"
}


resource "aws_iam_group" "pairing" {
  name = module.label.id

}

resource "aws_iam_group_policy_attachment" "application_bucket_get_acess" {
  group      = aws_iam_group.pairing.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_user" "pairing" {
  name = module.label.id
  path = "/user/"
}

resource "aws_iam_group_membership" "application" {
  name  = module.label.id
  group = aws_iam_group.pairing.name
  users = [
    aws_iam_user.pairing.name
  ]
}

resource "aws_iam_access_key" "applcation" {
  user = aws_iam_user.pairing.name
}

output "AWS_ACCESS_KEY_ID" {
  value = aws_iam_access_key.applcation.id
}

output "AWS_SECRET_ACCESS_KEY" {
  value = aws_iam_access_key.applcation.secret
}
