variable "bucket" {
  type        = string
  description = "Name of the S3 bucket"
}

variable "name" {
  type        = string
  description = "Name of the environment"
}

variable "region" {
  type        = string
  description = "AWS region where resources will be created"
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
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "vpc-ec2-rds"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "infrastructure-team"
}

