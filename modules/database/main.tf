resource "aws_db_subnet_group" "subnet_group" {
  name       = "${local.db_name}-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags       = local.common_tags
}

resource "random_password" "master" {
  length  = 24
  special = true
  override_special = "!#$%^&*()-_=+[]{}<>:?"
}

resource "aws_security_group" "security_group" {
  name_prefix = "${local.db_name}-"
  description = "Security group for ${local.db_name}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_security_group_ids
    content {
      description     = "Allow from ${ingress.value}"
      from_port       = var.engine == "postgres" ? 5432 : 3306
      to_port         = var.engine == "postgres" ? 5432 : 3306
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.db_name}-sg"
  })
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${local.db_name}-credentials"
  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.master.result
    engine   = var.engine
  })
}

resource "aws_db_instance" "db" {
  identifier     = local.db_name
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_encrypted = true

  db_subnet_group_name   = aws_db_subnet_group.subnet_group.name
  vpc_security_group_ids = [aws_security_group.security_group.id]

  username = var.master_username
  password = random_password.master.result

  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.db_name}-final-snapshot"

  tags = local.common_tags
}