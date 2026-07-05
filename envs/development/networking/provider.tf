terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 6.47"
    }
  }

  backend "s3" {
    bucket = "tf-infra-creation"
    key = "dev/networking.tfstate"
    region = "us-east-1"
    use_lockfile = true
    encrypt = true
  }
}

provider "aws" {
    region = "us-east-1"

    # auto tag each resource which created by this folder
    default_tags {
        tags = {
            Environment = "dev"
            Layer       = "networking"
            ManagedBy   = "Terraform"
        }
    }
}