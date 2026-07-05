variable "remote_state_bucket" {
    description = "Bucket name where state file is stored"
    type = string
}

variable "networking_state_key" {
    description = "Key name (state filename)"
    type = string
}

variable "cluster_version" {
    description = "This is cluster verison"
    type = string
}

variable "node_groups" {
    description = "Node groups vars"
    type = map(object({
        instance_types = list(string)
        desired_size   = number
        min_size       = number
        max_size       = number
    }))
}

