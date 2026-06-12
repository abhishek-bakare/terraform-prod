#VPC==>AZ(data)==>IGW==>subnet(public/private)==>route table for pub==>aws route==>aws route table association==>EIP==>NAT GW==>pvt subnet(ignore if already created)==>route table pvt==>aws route==>route table association==>NACL for public (if)==>SG(for pub, pvt, db)

#After installing Floci 

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


