terraform {
  required_version = "~>0.12.5"
}

provider "aws" {
  region  = "eu-west-2"
  version = "~> 2.40"
}

module "label" {
  source  = "cloudposse/label/terraform"
  version = "0.4.0"

  namespace  = "cormac"
  stage      = "dev"
  attributes = ["ci"]
  name       = "test"
}

