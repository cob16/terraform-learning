terraform {
  required_version = "~>0.12.24"
}

provider "aws" {
  alias   = "london"
  region  = "eu-west-2"
  version = "~> 2.60"
}

provider "aws" {
  alias   = "ireland"
  region  = "eu-west-1"
  version = "~> 2.60"
}

module "label" {
  source     = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=tags/0.4.0"
  namespace  = "cormac"
  stage      = terraform.workspace
  name       = "vpc-peering"
  attributes = ["test"]
  delimiter  = "-"
}

locals {
  london_cidr_block  = "10.0.0.0/16"
  ireland_cidr_block = "10.1.0.0/16" //cidir block is not allowed to conflict when peering
}

module "london" {
  providers = {
    aws = aws.london
  }
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> v2.0"
  name    = "${module.label.id}-london"
  cidr    = local.london_cidr_block

  azs = ["eu-west-2a"]
  intra_subnets = [
    cidrsubnet(local.london_cidr_block, 8, 1)
  ]

  enable_nat_gateway = false
  enable_vpn_gateway = false
}

module "ireland" {
  providers = {
    aws = aws.ireland
  }
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> v2.0"
  name    = "${module.label.id}-ireland"
  cidr    = local.ireland_cidr_block

  azs = ["eu-west-1a"]
  intra_subnets = [
    cidrsubnet(local.ireland_cidr_block, 8, 1)
  ]

  enable_nat_gateway = false
  enable_vpn_gateway = false
}

