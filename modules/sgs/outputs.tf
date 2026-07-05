output "sg_pub_id" {
  value = aws_security_group.sg_public.id
  description = "ID of pub SG"
}

output "sg_pvt_id" {
  value = aws_security_group.sg_private.id
  description = "ID of pvt SG"
}

output "sg_db_id" {
  value = aws_security_group.sg_database.id
  description = "ID of db SG"
}