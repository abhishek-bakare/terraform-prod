# cluster IAM role and KMS key
# creating iam policy document which assume roles for EKS
data "aws_iam_policy_document" "cluster_assume_role" {
    statement {
        effect = "Allow"
        actions = ["sts:AssumeRole"]
        principals {
            type = "Service"
            identifiers = ["eks.amazonaws.com"]
        }
    }
}

resource "aws_iam_role" "cluster" {
    assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json
    name = "${var.cluster_name}-cluster-role"

    tags = {
      Name = "${var.environment}-cluster-role"
      Environment = var.environment
      Terraform   = "true"
    }
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
    role = aws_iam_role.cluster.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# enabling KMS key for encypting EKS secrets
resource "aws_kms_key" "eks" {
    description = "EKS secrets encryption key for ${var.cluster_name}"
    enable_key_rotation = true          # Tells AWS to automatically rotate the underlying cryptographic material of this key once every year
    deletion_window_in_days = 7     # Sets a 7-day waiting period if you or Terraform attempt to delete this key
}

# retention policy for CW logs
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7 # Automatically purges old logs after 7 days to save money
}

# creating EKS cluster 
resource "aws_eks_cluster" "this_cluster" {
    name = var.cluster_name
    role_arn = aws_iam_role.cluster.arn
    version = var.cluster_version
    
    vpc_config {
      subnet_ids = var.subnet_ids
      endpoint_private_access = true
      endpoint_public_access = true     # set to true for practise but in prod we never do that, via VPN we can connect to cluster
      security_group_ids = [ var.security_group_pvt ]
    }

    access_config {
      authentication_mode = "API_AND_CONFIG_MAP"
      bootstrap_cluster_creator_admin_permissions = true
    }

    # enable control plane logging
    enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

    # enabling KMS for secrets encryption
    encryption_config {
      provider {
        key_arn = aws_kms_key.eks.arn
      } 
      resources = ["secrets"]
    }

    depends_on = [ aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy, aws_cloudwatch_log_group.eks ]
}

# node group IAM role
data "aws_iam_policy_document" "node_assume_group" {
    statement {
      effect = "Allow"
      actions = [ "sts:AssumeRole" ]
      principals {
        type = "Service"
        identifiers = [ "ec2.amazonaws.com" ]
      }
    }
}

# ADDED: Fix for 401 Unauthorized on public.ecr.aws (Rate Limiting)
data "aws_iam_policy_document" "node_ecr_public" {
  statement {
    effect = "Allow"
    actions = [
      "sts:GetServiceBearerToken",
      "ecr-public:GetAuthorizationToken",
      "ecr-public:BatchCheckLayerAvailability",
      "ecr-public:GetRepositoryPolicy",
      "ecr-public:DescribeRepositories",
      "ecr-public:DescribeImages",
      "ecr-public:DescribeImageTags",
      "ecr-public:DescribeRegistries",
      "ecr-public:GetRepositoryCatalogData",
      "ecr-public:GetRegistryCatalogData"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "node_ecr_public_policy" {
  name   = "${var.cluster_name}-node-ecr-public"
  policy = data.aws_iam_policy_document.node_ecr_public.json
}

# creating a node role
resource "aws_iam_role" "node" {
    name = "${var.cluster_name}-node-role"
    assume_role_policy = data.aws_iam_policy_document.node_assume_group.json

    tags = {
      Name = "${var.environment}-node-role"
      Environment = var.environment
      Terraform   = "true"
    }
}

# Standard EKS Worker Node Policies
resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    role = aws_iam_role.node.name
}

# we can also add VPC CNI policy pod level as configured below
resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    role = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    role = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_ecr_public_attachment" {
  policy_arn = aws_iam_policy.node_ecr_public_policy.arn
  role       = aws_iam_role.node.name
}

# managed node groups
resource "aws_eks_node_group" "this_nodes" {
    for_each = var.node_groups

    cluster_name = aws_eks_cluster.this_cluster.name
    node_group_name = "${var.cluster_name}-${each.key}"
    node_role_arn = aws_iam_role.node.arn
    subnet_ids = var.subnet_ids     # must be pvt subnets
    ami_type = "AL2023_x86_64_STANDARD"
    instance_types = each.value.instance_types

    scaling_config {
      desired_size = each.value.desired_size
      max_size = each.value.max_size
      min_size = each.value.min_size
    }

    depends_on = [ aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy, aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy ]
}

######
# EBS CSI driver setup
# trust policy for the pod
data "aws_iam_policy_document" "ebs_csi_assume_role" {
  statement {
    effect = "Allow"
    actions = [ "sts:AssumeRole", "sts:TagSession" ]
    principals {
      type = "Service"
      identifiers = [ "pods.eks.amazonaws.com" ]
    }
  }
}

# create the role
resource "aws_iam_role" "ebs_csi_driver" {
  name = "${var.cluster_name}-ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role.json

  tags = {
      Name = "${var.environment}-ebscsi-role"
      Environment = var.environment
      Terraform   = "true"
    }
}

# attach official AWS managed policy for EBS
resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role = aws_iam_role.ebs_csi_driver.name
}

# pod identity
resource "aws_eks_pod_identity_association" "ebs_csi_driver" {
  cluster_name    = aws_eks_cluster.this_cluster.name
  namespace       = "kube-system"
  service_account = "ebs-csi-controller-sa"
  role_arn        = aws_iam_role.ebs_csi_driver.arn
}

###########
# S3 mountpoint setup
# trust policy for the pod
data "aws_iam_policy_document" "s3_csi_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "s3_csi_role" {
  name = "${var.cluster_name}-s3-csi-role"
  assume_role_policy = data.aws_iam_policy_document.s3_csi_assume_role.json

  tags = {
      Name = "${var.environment}-s3-csi-role"
      Environment = var.environment
      Terraform   = "true"
    }  
}

data "aws_iam_policy_document" "s3_csi_policy" {
  statement {
    effect = "Allow"
    actions = [ "s3:ListBucket",
                "s3:GetObject",
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:DeleteObject" 
              ]
    resources = ["arn:aws:s3:::*", 
                  "arn:aws:s3:::*/*"]

  }
}

resource "aws_iam_policy" "s3_csi_policy" {
  name = "${var.cluster_name}-s3-csi-policy"
  policy = data.aws_iam_policy_document.s3_csi_policy.json
}

resource "aws_iam_role_policy_attachment" "s3_csi_driver_policy" {
  policy_arn = aws_iam_policy.s3_csi_policy.arn
  role = aws_iam_role.s3_csi_role.name
}

resource "aws_eks_pod_identity_association" "s3_csi_driver" {
  cluster_name    = aws_eks_cluster.this_cluster.name
  namespace       = "kube-system"
  service_account = "s3-csi-driver-sa" # The default ServiceAccount for the Mountpoint S3 driver
  role_arn        = aws_iam_role.s3_csi_role.arn
}

# lets add addons
resource "aws_eks_addon" "addons" {
  for_each = toset(["vpc-cni", "coredns", "kube-proxy", "eks-pod-identity-agent", "aws-ebs-csi-driver", "aws-mountpoint-s3-csi-driver"])
  cluster_name = aws_eks_cluster.this_cluster.name
  addon_name = each.value

  # Standard practice: don't overwrite custom configurations if we update the cluster
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [ aws_eks_node_group.this_nodes ]

}

resource "time_sleep" "wait_for_alb_webhook" {
  depends_on = [aws_eks_addon.addons]
  create_duration = "30s"
}

# Grant your personal AWS user Admin Access to the cluster
resource "aws_eks_access_entry" "local_admin" {
  cluster_name  = aws_eks_cluster.this.name
  # Change this to match your actual local IAM user or SSO role!
  principal_arn = "arn:aws:iam::059325865650:user/admin-abhishek" 
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "local_admin_policy" {
  cluster_name  = aws_eks_cluster.this.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_eks_access_entry.local_admin.principal_arn

  access_scope {
    type = "cluster"
  }
}