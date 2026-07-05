output "instance_id" {
    description = "The ID of the EC2 instance"
    value = aws_instance.ec2_server.id
}

output "pvt_ip" {
    description = "The private IP address of the instanc"
    value = aws_instance.ec2_server.private_ip
}

output "pub_ip" {
    description = "The public IP address of the instanc"
    value = aws_instance.ec2_server.public_ip
}

output "instance_arn" {
    description = "ARN of instance"
    value = aws_instance.ec2_server.arn
}