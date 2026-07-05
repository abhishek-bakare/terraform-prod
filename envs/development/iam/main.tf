data "aws_iam_policy_document" "s3_read_only" {
    statement {
      effect = "Allow"
      actions = [ "s3:GetObject", "s3:ListBucket" ]
      resources = ["arn:aws:s3:::tf-infra-creation","arn:aws:s3:::tf-infra-creation/*"]
    }
}

resource "aws_iam_policy" "s3_custom_policy" {
    name = var.policy_name
    policy = data.aws_iam_policy_document.s3_read_only.json
}

module "ec2_web_role" {
    source = "../../../modules/iam"
    role_name = var.role_name
    environment = var.environment

    trusted_service_principals = var.principals

    custom_policy_arns = {
      "ssm-managed" = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      "s3-list-get" = aws_iam_policy.s3_custom_policy.arn
    }

}