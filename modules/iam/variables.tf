variable "project_name" {
  type    = string
  default = "cob"
}

variable "environment" {
  type = string   

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "role_purpose" {
  description = "Short identifier for what this role is for, used in naming (e.g.'ecs-execution')"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "trusted_service" {
  description = "AWS service principal that assumes this role"
  type        = string

  validation {
    condition = contains([
      "ec2.amazonaws.com",
      "ecs.amazonaws.com",
      "ecs-tasks.amazonaws.com",
      "lambda.amazonaws.com",
      "glue.amazonaws.com"
    ], var.trusted_service)
    error_message = "trusted_service must be a supported AWS service principal."
  }
}

variable "policy_statements" {
  description = "Explicit IAM policy statements this role needs"
  type = list(object({
    sid       = string
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

variable "managed_policy_arns" {
  description = "Optional AWS-managed policy ARNs to attach"
  type        = list(string)
  default     = []
}