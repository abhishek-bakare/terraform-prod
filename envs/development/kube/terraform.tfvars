remote_state_bucket = "tf-infra-creation"
networking_state_key = "dev/networking.tfstate"
cluster_version = "1.35"
node_groups = {
    # node group 1
  "node-1" = {
    instance_types = ["t3.small", "c7i-flex.large"]
    desired_size   = 3
    min_size       = 1
    max_size       = 4
  }
}

repository_name = "dev-web-app-ecr"
taggs = {
  environment = "dev"
  ManagedBy   = "terraform"
  Project     = "core-apps"
}