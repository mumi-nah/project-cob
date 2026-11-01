output "db_instance_id" {
  value = aws_db_instance.db.id
}

output "db_endpoint" {
  value = aws_db_instance.db.endpoint
}

output "db_port" {
  value = aws_db_instance.db.port
}

output "secret_arn" {
  description = "Secrets Manager ARN holding the username/password/engine"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "security_group_id" {
  value = aws_security_group.security_group.id
}