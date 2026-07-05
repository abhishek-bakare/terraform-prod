variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  #default     = "test-vpc"
}

variable "vpc_env" {
  description = "VPC environment"
  type        = string
  #default     = "Dev"
}

variable "my_vpc_id" {
    description = "VPC ID"
    type = string
}

variable "vpc_cidr_block" {
    description = "VPC CIDR block"
    type = string
}

variable "cluster_name" {
  description = "Cluster name for Karp"
  type = string
}