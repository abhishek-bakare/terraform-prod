output "my_pub_subnet1" {
  value = aws_subnet.my_pub_subnet1.id
}

output "my_pvt_subnet1" {
  value = aws_subnet.my_pvt_subnet1.id
}

output "my_pub_subnet2" {
  value = aws_subnet.my_pub_subnet2.id
}

output "my_pvt_subnet2" {
  value = aws_subnet.my_pvt_subnet2.id
}

output "my_vpc_id" {
  value = aws_vpc.aws_vpc_myvpc.id
}

output "vpc_cidr_block" {
  value = aws_vpc.aws_vpc_myvpc.cidr_block
}