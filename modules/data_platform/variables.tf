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

variable "data_platform_purpose" {
  description = "Short identifier for what this capability is for, used in naming"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "s3_data_location" {
  description = "s3://bucket/prefix the crawler should scan"
  type        = string
}

variable "crawler_role_arn" {
  description = "IAM role ARN the crawler assumes (from the iam module, trusted_service = glue.amazonaws.com)"
  type        = string
}

variable "crawler_schedule" {
  description = "Cron expression for automatic crawler runs. Leave null to run only on demand."
  type        = string
  default     = null
}

variable "athena_results_s3_uri" {
  description = "s3://bucket/prefix where Athena writes query results"
  type        = string
}

