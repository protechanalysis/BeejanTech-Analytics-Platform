terraform {
  required_providers {
    required_version = ">= 1.13.3"

    aws = {
      source  = "hashicorp/aws"
      version = "~>6.5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}

provider "aws" {
  # Configuration options
}

provider "random" {
  # Configuration options
}