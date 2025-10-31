variable "bucket" {
  type        = string
  description = "Name of the S3 bucket"
}

variable "name" {
  type        = string
  description = "Name of the environment"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "vpc-ec2-rds"
}

