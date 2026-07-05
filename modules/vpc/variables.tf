variable "vpc_cidr" {
  description = "CIDR for VPC"
  type        = string
  default     = "192.168.0.0/16"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "test-vpc"
}

variable "vpc_env" {
  description = "VPC environment"
  type        = string
  default     = "Dev"

}

variable "pub_subnet_cidr_1" {
  description = "CIDR for subnet 1"
  type        = string
  default     = "192.168.1.0/24"
}

variable "pub_subnet_cidr_2" {
  description = "CIDR for subnet 2"
  type        = string
  default     = "192.168.2.0/24"
}

variable "pvt_subnet_cidr_1" {
  description = "CIDR for pvt subnet 1"
  type        = string
  default     = "192.168.3.0/24"
}

variable "pvt_subnet_cidr_2" {
  description = "CIDR for pvt subnet 2"
  type        = string
  default     = "192.168.4.0/24"
}

variable "cluster_name" {
  description = "Cluster name for Karpenter tag"
  type = string
}

