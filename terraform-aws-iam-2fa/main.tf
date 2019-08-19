provider "aws" {
  region  = "eu-west-2"
  version = "~> 1.56"
}

# comment this out on first run
#terraform {
#  backend "s3" {
#    encrypt        = true
#    bucket         = "ceb-terraform-remote-state-storage-s3"
#    dynamodb_table = "ceb-terraform-state-lock-dynamo" # locks changes when running in a team enviroment
#region         = "eu-west-2"
#    key            = ".terraform/terraform.tfstate"
#  }
#}

module "iam" {
  source = "./iam"
}
