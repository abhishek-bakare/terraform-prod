variable "policy_name" {
    description = "Name of the policy name"
    type = string
}

variable "role_name" {
    description = "Role name"
    type = string
}

variable "environment" {
    description = "Which env"
    type = string
}

variable "principals" {
    description = "Principals list"
    type = list(string)
}
