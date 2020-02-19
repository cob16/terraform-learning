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

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> v2.0"
  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = module.label.tags
}


output "VPC_ID" {
  value = module.vpc.vpc_id
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "public_subnets" {
  value = module.vpc.public_subnets
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
