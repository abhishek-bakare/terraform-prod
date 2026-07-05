terraform {
    required_version = ">= 1.10"

    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 6.47"
      }

      helm = {
        source = "hashicorp/helm"
        version = "~> 2.0"
      }

      kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    }

    backend "s3" {
    bucket = "tf-infra-creation"
    key = "dev/eks.tfstate"
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

provider "helm" {
    kubernetes  {
        host = module.eks_cluster.cluster_endpoint
        cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)

        # automatically generates a temp login token using AWS local CLI role
        exec {
          api_version = "client.authentication.k8s.io/v1beta1"
          args = ["eks", "get-token", "--cluster-name", module.eks_cluster.cluster_name]
          command = "aws"
      }
    }
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_cluster.cluster_name
}

provider "kubectl" {
  host = module.eks_cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)
  token = data.aws_eks_cluster_auth.cluster.token
  load_config_file = false
}