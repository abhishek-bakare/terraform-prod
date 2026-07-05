output "cluster_name" {
    description = "Name of EKS cluster"
    value = module.eks_cluster.cluster_name
}

output "cluster_endpoint" {
    description = "Endpoint of cluster"
    value = module.eks_cluster.cluster_endpoint
}

output "karpenter_node_role" {
    description = "IAM role that Karp assigns to newly launched EC2 instances"
    value = module.karpenter.karp_node_name
}

# we need this ID to configure ArgoCD deployment
output "vault_kms_key_id" {
    description = "used for auto-unseal vault"
    value = module.vault_aws.kms_key_id
}