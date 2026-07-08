# down official IAM policy for load balancer
data "http" "name" {
    url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json"
}

# create the policy
resource "aws_iam_policy" "alb_policy" {
    name = "${var.cluster_name}-AWSLoadBalancerControllerIAMPolicy"
    policy = data.http.name.response_body
    description = "Permissions for the AWS Load Balancer Controller"
}

# creating the trust policy
data "aws_iam_policy_document" "lbc_trust" {
    statement {
      effect = "Allow"
      actions = [ "sts:AssumeRole", "sts:TagSession" ]

      principals {
        type = "Service"
        identifiers = [ "pods.eks.amazonaws.com" ]
      }
    }
}

# create the role and attach the policy
resource "aws_iam_role" "lbc" {
    assume_role_policy = data.aws_iam_policy_document.lbc_trust.json
    name = "${var.cluster_name}-aws-lbc-role"

    tags = {
      Name = "${var.environment}-cluster-role"
      Environment = var.environment
      Terraform   = "true"
    }
}

resource "aws_iam_role_policy_attachment" "lbc_attach" {
    policy_arn = aws_iam_policy.alb_policy.arn
    role = aws_iam_role.lbc.name
}

# bind pod identity k8 SA
resource "aws_eks_pod_identity_association" "lbc" {
    cluster_name = var.cluster_name
    namespace = "kube-system"
    service_account = "aws-load-balancer-controller"
    role_arn = aws_iam_role.lbc.arn
}

# deploy the controller via helm
resource "helm_release" "lbc" {
    name = "aws-load-balancer-controller"
    repository = "https://aws.github.io/eks-charts"
    chart = "aws-load-balancer-controller"
    namespace = "kube-system"
    version = "1.7.2"

    set {
      name = "clusterName"
      value = var.cluster_name
    }

    set {
      name = "vpcId"
      value = var.vpcid
    }

    set {
      name = "serviceAccount.create"
      value = "true"
    }

    set {
      name = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    }

    depends_on = [ aws_eks_pod_identity_association.lbc ]
}

resource "time_sleep" "wait_for_alb_webhook" {
  depends_on = [helm_release.lbc]
  create_duration = "45s"
}

