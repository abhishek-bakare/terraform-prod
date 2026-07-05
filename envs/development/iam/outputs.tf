output "ec2_web_profile_name" {
  description = "The IAM instance profile for Dev web servers"
  value       = module.ec2_web_role.instance_prof_name
}