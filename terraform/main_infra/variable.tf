variable "bucket" {
  type        = string
  description = "Name of the S3 bucket"
}

variable "name" {
  type        = string
  description = "Name of the environment"
}

variable "keypair" {
  type        = string
  description = "Name of the SSH key pair to use for EC2 instances"
}

variable "allowed_cidr_blocks" {
  type        = string
  description = "CIDR blocks allowed for security group rules"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "Beejan_Cloud_Project"
}


