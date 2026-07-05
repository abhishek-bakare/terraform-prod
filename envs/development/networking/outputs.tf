output "pub_subnet_1" {
    description = "Subnet id of pub subnet 1"
    value = module.vpc.my_pub_subnet1
}

output "pub_subnet_2" {
    description = "Subnet id of pub subnet 2"
    value = module.vpc.my_pub_subnet2
}

output "pvt_subnet_1" {
    description = "Subnet of pvt subnet 1"
    value = module.vpc.my_pvt_subnet1
}

output "pvt_subnet_2" {
    description = "Subnet of pvt subnet 2"
    value = module.vpc.my_pvt_subnet2
}

output "vpc_id" {
    description = "ID of vpc"
    value = module.vpc.my_vpc_id
}

output "vpc_cidr" {
    description = "VPC CIDR"
    value = module.vpc.vpc_cidr_block
}

output "eks_sg_id" {
    value = module.security_groups.sg_pvt_id
}

output "cluster_name" {
    description = "This is cluster name"
    value = var.cluster_name
}

output "environment" {
    description = "This is env"
    value = var.vpc_env
}