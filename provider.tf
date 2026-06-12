terraform {
  required_version = ">= 1.10"

  backend "s3" {
    bucket = "my-test-tf-vpc"
    #path where state file resides
    key = "dev/boss.tfstate"
    region = "us-east-1"
    use_lockfile = true
    encrypt = true    #encrypt state file in s3
    
  }
}

variable "aws_assume_role" {
  description = "Used for provider role"
  type = string
}

provider "aws" {
  region = "us-east-1"

  # in prod we never use hardcoded access keys, we use role like below
  assume_role {
  #  # The ARN of the IAM role you want Terraform to assume
    role_arn     = var.aws_assume_role
    
  #  # Optional: A session name to identify who/what made the changes in AWS CloudTrail
    session_name = "GitHubActions-TF"
  }
}