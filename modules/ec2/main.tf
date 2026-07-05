resource "aws_instance" "ec2_server" {
    ami = var.ami_id
    instance_type = var.instance_type
    subnet_id = var.subnet_id
    key_name = var.key_name
    vpc_security_group_ids = var.security_group
    iam_instance_profile = var.iam_instance_profile  #attaching profile to pass iam role
    user_data = var.user_data
    associate_public_ip_address = var.public_ip_enable
    # checkov:skip=CKV_AWS_126: Ensure detailed monitoring is enabled
    #monitoring = true

    # Checkov:CKV_AWS_8: Ensure root block device is encrypted
    root_block_device {
      volume_size = var.volume_size
      encrypted = true
      volume_type = "gp3"
      delete_on_termination = true
    }

    # Checkov CKV_AWS_79: Require IMDSv2 for secure metadata access
    metadata_options {
      http_endpoint = "enabled"
      http_tokens = "required"
      http_put_response_hop_limit = 1
    }

    tags = {
      Name = "${var.environment}-${var.name}"
      Environment = var.environment
      Terraform = true
    }

}