variable "vpc_cidr" {
    description = "VPC CIDR"
    type = string
}

variable "vpc_name" {
    description = "VPC name"
    type = string
}

variable "vpc_env" {
    description = "Which ENV"
    type = string
}

variable "pub_subnet_cidr_1" {
    description = "Pub subnet 1 CIDR"
    type = string
}

variable "pub_subnet_cidr_2" {
    description = "Pub subnet 2 CIDR"
    type = string
}

variable "pvt_subnet_cidr_1" {
    description = "Pvt subnet 1 CIDR"
    type = string
}

variable "pvt_subnet_cidr_2" {
    description = "Pvt subnet 2 CIDR"
    type = string
}

variable "cluster_name" {
    description = "name of cluster for Karp"
    type = string
}