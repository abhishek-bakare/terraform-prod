# create IAM policy document
data "aws_iam_policy_document" "eso_policy" {
    statement {
      effect = "Allow"
      actions = [ "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds" ]
      resources = [  ]
                
    }
}