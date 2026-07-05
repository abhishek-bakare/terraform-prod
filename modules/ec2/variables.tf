variable "ami_id" {
    description = "This is AMI ID"
    type = string
}

variable "instance_type" {
    description = "This is instance type"
    type = string
}

variable "subnet_id" {
    description = "This is subnet ID"
    type = string
}

variable "key_name" {
    description = "Key pair name"
    type = string
    default = "mykp.pem"
}

variable "security_group" {
    description = "List of SGs for EC2"
    type = list(string)
}

variable "iam_instance_profile" {
    description = "The IAM Instance Profile to attach to the instance"
    type = string
    default = null
}

variable "user_data" {
    description = "The user data script to run on boot" 
    type = string
    default = ""
}

variable "public_ip_enable" {
    description = "Whether to associate a public IP address with an instance in a VPC"
    type = bool
    default = false
}

variable "volume_size" {
    description = "The size of the root volume in GB"
    type = number
    default = 8
}

variable "environment" {
    description = "The deployment environment (e.g., dev, staging, prod)"
    type = string
}

variable "name" {
    description = "The name of the EC2 instance"
    type = string
}