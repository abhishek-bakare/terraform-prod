variable "cluster_name" {
    description = "Name of the EKS cluster"
    type = string
}

variable "environment" {
    description = "Env"
    type = string
}

variable "cluster_version" {
    description = "EKS cluster version"
    type = string
    default = "1.33"
}

variable "subnet_ids" {
    description = "Subnet IDs"
    type = list(string)
}

variable "node_groups" {
    description = "Map of EKS managed node group definitions to create"
    type = map(object({
        instance_types = list(string)
        desired_size = number
        min_size = number
        max_size = number
    }))
}

variable "security_group_pvt" {
    description = "SG for EKS"
    type = string
}

variable "vpc_id" {
    description = "VPC id"
    type = string
}
