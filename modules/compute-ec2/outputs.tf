output "instance_id" {
  value = aws_instance.instance.id
}

output "private_ip" {
  value = aws_instance.instance.private_ip
}

output "public_ip" {
  description = "Null unless associate_public_ip is true"
  value       = var.associate_public_ip ? aws_instance.instance.public_ip : null
}

output "security_group_id" {
  value = aws_security_group.security_group.id
}