variable "project_name" {
  type    = string
  default = "cob"
}

variable "environment" {
  type = string   # required, no default — same rationale as every module

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "db_purpose" {
  description = "Short identifier for what this database is for, used in naming"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "vpc_id" {
  description = "VPC ID (from the networking module)"
  type        = string
}

variable "private_subnet_ids" {
  description = "At least 2 private subnet IDs, in different AZs (from the networking module)"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "RDS requires subnets in at least 2 AZs."
  }
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect to this database (e.g. a compute-ec2 or ECS task security group)"
  type        = list(string)
  default     = []
}

variable "engine" {
  description = "postgres or mysql"
  type        = string

  validation {
    condition     = contains(["postgres", "mysql"], var.engine)
    error_message = "engine must be postgres or mysql."
  }
}

variable "engine_version" {
  type = string
}

variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "master_username" {
  type    = string
  default = "dbadmin"
}

variable "multi_az" {
  description = "Run a standby replica in a second AZ for failover. false for dev, true for prod."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Days to retain automated backups"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Prevent accidental deletion via the AWS API/console"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip taking a final snapshot on destroy. Keep false outside of throwaway/test databases."
  type        = bool
  default     = false
}