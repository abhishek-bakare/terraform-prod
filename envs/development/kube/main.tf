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

module "aws_lbc" {
    source = "../../../modules/aws_lbc"
    environment = data.terraform_remote_state.networking.outputs.environment
    vpcid = data.terraform_remote_state.networking.outputs.vpc_id
    cluster_name = module.eks_cluster.cluster_name

    depends_on = [ module.eks_cluster ]
}

module "argocd" {
    source = "../../../modules/argocd"
    cluster_name = module.eks_cluster.cluster_name
    environment = data.terraform_remote_state.networking.outputs.environment

    depends_on = [ module.eks_cluster, module.karpenter ]
}

module "vault_aws" {
    source = "../../../modules/vault_aws"
    environment = data.terraform_remote_state.networking.outputs.environment
    cluster_name = module.eks_cluster.cluster_name
}

