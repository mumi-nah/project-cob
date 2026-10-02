output "role_arn" {
  value = aws_iam_role.role.arn
}

output "role_name" {
  value = aws_iam_role.role.name
}

output "instance_profile_name" {
  description = "Only set when trusted_service is ec2.amazonaws.com, otherwise null"
  value       = try(aws_iam_instance_profile.instance[0].name, null)
}