variable "project_name" {
  type    = string
  default = "cob"
}

variable "environment" {
  type = string   # required, no default — same rationale as networking/iam

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "bucket_purpose" {
  description = "Short identifier for what this bucket is for, used in naming"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "force_destroy" {
  description = "Allow bucket deletion including locked objects."
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Whether to enable versioning for the bucket."
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description  = "List of lifecycle rules to apply to the bucket. Each rule is a map with keys: id, prefix, tags, transitions, expiration."
  type        = list(object({
    id          = string
    prefix      = string
    tags        = optional(map(string))
    transition_days          = number
    transition_storage_class = string
    expiration_days          = optional(number)
    }))
    default     = []
}