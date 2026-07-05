# build the VPC
module "vpc" {
    source = "../../../modules/vpc"
    vpc_cidr = var.vpc_cidr
    vpc_name = var.vpc_name
    vpc_env = var.vpc_env
    pub_subnet_cidr_1 = var.pub_subnet_cidr_1
    pub_subnet_cidr_2 = var.pub_subnet_cidr_2
    pvt_subnet_cidr_1 = var.pvt_subnet_cidr_1
    pvt_subnet_cidr_2 = var.pvt_subnet_cidr_2
    cluster_name = var.cluster_name
}

module "security_groups" {
    source = "../../../modules/sgs"
    my_vpc_id = module.vpc.my_vpc_id
    vpc_cidr_block = module.vpc.vpc_cidr_block
    cluster_name = var.cluster_name
    vpc_name = var.vpc_name
    vpc_env = var.vpc_env
}