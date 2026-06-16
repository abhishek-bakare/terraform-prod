To setup actions like as per IT industries we use below steps:
1. Create a repo on GH
2. Create your feature branches with name like this 'feature/abhishek'
3. Push code to the feature branch only
4. Create branches in local for staging, main
5. Apply Branch protections rules on GH in settings ==> Branch ==> Add branch rules 
    - Require a pull request before merging
    - Require approvals
    - Dismiss stale pull request approvals when new commits are pushed
    - Require status checks to pass before merging
    - Require branches to be up to date before merging
    - Block force pushes and deletions
6. Add CODEOWNERS file in the .github dir so only assigned persons can review the code
  CODEOWNERS
  '''
    # Default reviewers for everything
    * @devops-team

    # Only the security team can approve changes to IAM roles or policies
    modules/iam/ @security-team

    # Only the lead cloud engineers can approve changes to networking
    modules/vpc/ @lead-cloud-engineers
  '''
7. Create the GH Environment protections Settings ==> Environment
    - Create new Env called production
    - Check Required Reviewers
8. Now we need to create trust policy bet GH and AWS using OIDC
    - Create OIDC provider first in AWS Search Identity provider ==> Add provider ==> Add below thing
    Provider: token.actions.githubusercontent.com
    Audinence: sts.amazonaws.com
    - Now create 1 or 2 IAM roles using below policy
    '''
    {
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Federated": "arn:aws:iam::<AWS_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
            "StringEquals": {
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
            },
            "StringLike": {
            "token.actions.githubusercontent.com:sub": "repo:<YOUR_USERNAME>/<YOUR_REPO_NAME>:*"
            }
        }
        }
    ]
    }
    '''
    - I have created 2 roles 1 for only plan and 2 for only apply with :sub": "repo:<YOUR_USERNAME>/<YOUR_REPO_NAME>:environment:production". Means apply step only trigger if we mentioned env as a prod and 1 time resources will be created.
9. Now you may think if we already have role_arn in provider file then why we required this OIDC and roles? Simple ans role we provided in provider is empty it needs to login first with AWS account to assume the role. Here GH OIDC roles helps us it gives us temp logins for that role_arn to work.
10. Now we need to add role_arn to the provider.tf
    - If you are using multi aws accounts for diff envs like dev, staging, prod then you can use this repo strategy from provider.tf file like creating variable, etc.
    - If you have single account then no need to add role_arn block as when pipeline runs it already have short lived role created by OIDC roles, Tf can smartly used that.
11. Now lets start to write the pipline
    - Setup event triggers (pull_request, push)
    - Setup Permissions (id-token: write,contents: read, pull-requests: write)
    - Setup env for AWS_REGION, TF_VERSION, AWS_ACCOUNT_ID
    - Do the concurrency step
    - In the 1st job we are doing below things
        - Checkout code
        - Setup AWS credentials using aws-actions/configure-aws-credentials@v4
        - Setup Terraform using hashicorp/setup-terraform@v3
        - TF fmt check using terraform fmt -check -recursive
        - TF init
        - Setup TFlint using terraform-linters/setup-tflint@v4
        - Run tflint -f compact
        - Run checkov using bridgecrewio/checkov-action@v12
        - If required setup Infracost action so get costing
        - TF plan cmd terraform plan -no-color -out=tfplan > plan.txt