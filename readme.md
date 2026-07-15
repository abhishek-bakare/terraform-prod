#VPC==>AZ(data)==>IGW==>subnet(public/private)==>route table for pub==>aws route==>aws route table association==>EIP==>NAT GW==>pvt subnet(ignore if already created)==>route table pvt==>aws route==>route table association==>NACL for public (if)==>SG(for pub, pvt, db)

Now create S3 bucket and DynamoDB instance so we can utilize state locking.
#aws s3 mb s3://my-bucket

Note: TF state file is very important so when you keep it in S3 bucket ensure that you have enable versioning, added Deny deletion policy, enable MFA for deletion & also turn on s3 object lock (write once read many)

#aws dynamodb create-table `
    --table-name terraform-lock-table `
    --attribute-definitions AttributeName=LockID,AttributeType=S `
    --key-schema AttributeName=LockID,KeyType=HASH `
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1

Create Terraform workspace where you required and then create provider.tf like here

#aws ec2 create-key-pair --key-name MyKeyPair --query "KeyMaterial" --output text > MyKeyPair.pem

1. Lets see how real IT industries manages diff environment
    - They mostly never use "terraform workspace new <env>" cmd (bcaz they used same backend, they do not create separate folder structure)
    - Instead of using cmd they use separate folders for each env and create backend.tf for each
├── modules/
│   ├── vpc/
│   └── ec2/
└── environments/
    ├── staging/
    │   ├── backend.tf  # Points to Staging S3 Bucket
    │   ├── main.tf     # Calls modules with staging variables
    │   └── variables.tf
    └── production/
        ├── backend.tf  # Points to Production S3 Bucket
        ├── main.tf     # Calls modules with production variables
        └── variables.tf
2. Lets create below modules
    - VPC module (except sec groups) /modules/vpc
    - Sec groups /modules/sgs
    - IAM roles /modules/iam
        - While creating sgs modules we needed vpc_id and vpc_cidr_host to be put in outputs
        - When creating IAM roles we follow below guidelines
            1. Never use raw json strings, we use TF aws_iam_policy_document, it will catch syntax errors if any
            2. Never use inline policies: do not embed policies directly inside the role. We use aws_iam_role_policy_attachment.
            3. Looping attachment: A good module should allow you to pass alist of 5 diff policy ARNs
3. Now lets understand some concepts, we created TF modules with main, var, outputs. When we call them in our envs there also we need to create output file if we are using diff folders for resources like networking, sg, iam, eks, etc. 
We need to use data reosurce "data.terraform_remote_state" to fetch subnets, iam, etc so it will fetch from outputs that we created in env/staging/networking or env/staging/iam, etc.
"data.terraform_remote_state" is using .tfstate file to fetch the data.
If we not used data resource then it ask for value at the time of execution.
4. For EKS module we are using Karpenter to so our cost will be less, but still we required 2-3 initial nodes on Amazon linux so core networking components like CoreDNS, VPC CNI & Karpenter will be installed and then when we deploying Application related pods then Karpeter can create new EC2 instances.
We will be creating separate module for Karpenter with Karp node role similar to 2 initial nodes
If you do not want to use AmazonLinux as a initial nodes then we need to configure 3 things as below
    - create aws_ami object. Use owner, filter method
    - Create launch template with image_id, instance_type, etc
    - Attach it to node groups aws_eks_node_group as a launch_template 
5. Now lets create the actual ENVs
6. For AWS load balancer we are using AWS load balancer controller and install it using helm release then we also installing NGINX ingress controller using helm release.
    - AWS LBS is not actual load balance its just a pod/controller sits in our cluster and watches K8 files & then call AWS API to build actual LB.
    - NGINX is what which stands inside the front doors of our cluster which actual routes the traffic.
    - When we deploy NGINX into cluster it has note attached says "I need internet-facing NLB"
    - AWS LBS sees this note talks to AWS API and launch NLB, this NLB points to NGINX pods
    - Now whenever user hits the URL it comes on NLB, LB passes to NGINX controller and NGINX then route to the actual app.
    - Now Q arises how LBC knows in which subnets to launch the NLB or internet-facing LB's are needs to be in public subnets how lbc will know this.
    Here it uses feature called subnet discovery via tags means we need to add below tags in respective subnets just like we added for Karp.
    For public subnets (internet facing): "kubernetes.io/role/elb" = "1"
    For pvt subnets (internal LB): "kubernetes.io/role/internal-elb" = "1"
    We can also do this using manual way in helm release we need to use set like below
    set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-subnets"
    value = "subnet-0123456789abcde,subnet-0abcdef12345678"
    }
7. Now coming to AWS secrets manager, we need to create the secrets manager for strong secrets safely. But here you can say we are already used kms block in eks_cluster then why we needed AWS SM.
    - First kms we used which is used to encrypt the secrets in etcd means whole etcd is encrypted here.
    - But if we used Secrets manifest we need to use base64/plaintext secrets which are visible on Git
    - So here first created SM, stores the secrets and use ESO and secretstore to fetch it, once ESO fetch it then it will be safely encrypted on the cluster's hard drive.
    - So first create the secrets manually on AWS console and store it, take ARN of the use in module
    - Then you need to create ClusterSecretStore/SecretStore and ExternalSecret
8. Next is ArgoCD deployment through helm_release via terraform. You can see i used normal EOT instead of yamlencode bcaz TF unable to create intenet-facing LB. I wasted my whole day to debug the issue but using normal yaml syntax worked.
9. Lets create vault now, for Vault we are creating AWS KMS key which can do auto-unseal work so no human intevention required. Then using argocd yaml maifest we are going to deploy Hashicorp Vault.
I also created the StorageClass so Vault can get the persistent storage


# helm show values sonarqube --repo https://SonarSource.github.io/helm-chart-sonarqube --version 10.5.1
To see values use above cmd

