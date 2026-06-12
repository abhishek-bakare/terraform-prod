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

output "sg_public" {
  value = aws_security_group.sg_public.id
}

output "sg_private" {
  value = aws_security_group.sg_private.id
}

output "sg_database" {
  value = aws_security_group.sg_database.id
}