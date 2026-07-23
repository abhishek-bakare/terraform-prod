variable "repository_name" {
    description = "Repo name"
    type = string
}

variable "taggs" {
    description = "This is tags"
    type = map(string)
    default = {}
}