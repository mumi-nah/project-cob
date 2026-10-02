variable "project_name" {
  type    = string
  default = "cob"
}

variable "environment" {
  type = string   # required, no default — same rationale as every other module

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "instance_purpose" {
  description = "Short identifier for what this instance is for, used in naming"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "vpc_id" {
  description = "VPC ID this instance's security group belongs to (from the networking module)"
  type        = string
}

variable "subnet_id" {
  description = "Subnet to launch the instance into (from the networking module)"
  type        = string
}

variable "instance_profile_name" {
  description = "Instance profile to attach (from the iam module). Leave null for no IAM role."
  type        = string
  default     = null
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ami_id" {
  description = "AMI to use. Leave null to auto-select the latest Amazon Linux 2023 AMI."
  type        = string
  default     = null
}

variable "ingress_rules" {
  description = "Explicit inbound rules for this instance's security group"
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = {}
}

variable "root_volume_size" {
  type    = number
  default = 20
}

variable "associate_public_ip" {
  description = "Whether to auto-assign a public IP. Should be false for any instance in a private subnet."
  type        = bool
  default     = false
}