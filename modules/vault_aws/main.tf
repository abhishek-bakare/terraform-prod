resource "aws_kms_key" "vault" {
    description = "Vault auto-unseal key for ${var.cluster_name}"
    deletion_window_in_days = 7
    enable_key_rotation = true
}

resource "aws_kms_alias" "vault" {
    target_key_id = aws_kms_key.vault.key_id
    name = "alias/${var.cluster_name}-vault-unseal"
}

# creating trust policy
data "aws_iam_policy_document" "vault_trust" {
    statement {
      effect = "Allow"
      actions = [ "sts:AssumeRole", "sts:TagSession" ]
      principals {
        type = "Service"
        identifiers = [ "pods.eks.amazonaws.com" ]
      }
    }
}

resource "aws_iam_role" "vault" {
    name = "${var.cluster_name}-vault-role"
    assume_role_policy = data.aws_iam_policy_document.vault_trust.json

    tags = {
        Name        = "${var.cluster_name}-vault-role"
        Environment = var.environment
        Terraform   = "true"
    }
}

data "aws_iam_policy_document" "vault_kms" {
    statement {
      effect = "Allow"
      actions = [ 
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:DescribeKey"
       ]
      resources = [ aws_kms_key.vault.arn ]
    }
}

resource "aws_iam_role_policy" "vault_kms" {
    policy = data.aws_iam_policy_document.vault_kms.json
    role = aws_iam_role.vault.id
    name = "vault-kms-unseal-policy"
}

resource "aws_eks_pod_identity_association" "vault" {
    cluster_name = var.cluster_name
    service_account = "vault"
    namespace = "vault"
    role_arn = aws_iam_role.vault.arn
}
