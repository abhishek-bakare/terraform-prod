data "terraform_remote_state" "networking" {
    backend = "s3"
    config = {
      bucket = var.remote_state_bucket
      key = var.networking_state_key
      region = "us-east-1"
    }
}

module "eks_cluster" {
    source = "../../../modules/eks"

    cluster_name = data.terraform_remote_state.networking.outputs.cluster_name
    cluster_version = var.cluster_version
    environment = data.terraform_remote_state.networking.outputs.environment
    vpc_id = data.terraform_remote_state.networking.outputs.vpc_id
    subnet_ids = [data.terraform_remote_state.networking.outputs.pvt_subnet_1, data.terraform_remote_state.networking.outputs.pvt_subnet_2]
    security_group_pvt = data.terraform_remote_state.networking.outputs.eks_sg_id

    node_groups = var.node_groups
}

module "karpenter" {
    source = "../../../modules/karpenter"

    environment = data.terraform_remote_state.networking.outputs.environment
    cluster_name = module.eks_cluster.cluster_name
    cluster_endpoint = module.eks_cluster.cluster_endpoint
    cluster_id = module.eks_cluster.cluster_id

    depends_on = [ module.eks_cluster ]
}

resource "kubectl_manifest" "nodepool_ec2nodeclass" {
  for_each = fileset("${path.module}", "*.yaml")
  yaml_body = file("${path.module}/${each.value}")

  depends_on = [ module.eks_cluster, module.karpenter.helm_release.karpenter ]
}

module "aws_lbc" {
    source = "../../../modules/aws_lbc"
    environment = data.terraform_remote_state.networking.outputs.environment
    vpcid = data.terraform_remote_state.networking.outputs.vpc_id
    cluster_name = module.eks_cluster.cluster_name

    depends_on = [ module.eks_cluster ]
}

module "nginx_ingress" {
    source = "../../../modules/nginx"
    cluster_name = module.eks_cluster.cluster_name
    public_subnet_ids = [data.terraform_remote_state.networking.outputs.pub_subnet_1, 
                        data.terraform_remote_state.networking.outputs.pub_subnet_2]

    depends_on = [ module.aws_lbc, module.karpenter ]
}

module "argocd" {
    source = "../../../modules/argocd"
    cluster_name = module.eks_cluster.cluster_name
    environment = data.terraform_remote_state.networking.outputs.environment

    depends_on = [ module.eks_cluster, module.nginx_ingress, module.karpenter ]
}

module "vault_aws" {
    source = "../../../modules/vault_aws"
    environment = data.terraform_remote_state.networking.outputs.environment
    cluster_name = module.eks_cluster.cluster_name
}

