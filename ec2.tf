#import module
module "vpc" {
  source = "./modules/vpc"

}

locals {
  instances = {
    ubuntu = {
      ami           = "ami-0a2b6680ef4ed0596"
      instance_type = "t3.micro"
      subnet_id     = module.vpc.my_pub_subnet1
    }

    amazonlinux-1 = {
      ami           = "ami-0ff8a91507f77f867"
      instance_type = "t3.medium"
      subnet_id     = module.vpc.my_pvt_subnet1
    }
  }
}



resource "aws_instance" "test_ec2" {
  for_each                    = local.instances
  ami                         = each.value.ami
  instance_type               = each.value.instance_type
  ebs_optimized               = true
  key_name                    = "my-kp"
  subnet_id                   = each.value.subnet_id
  vpc_security_group_ids      = each.key == "ubuntu" ? [module.vpc.sg_public] : [module.vpc.sg_private]
  associate_public_ip_address = each.key == "ubuntu" ? true : false

}