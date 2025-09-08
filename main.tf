terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "my-terraform-state-bucket"  # Replace with your S3 bucket name
    key            = "state/${var.app_name}/${var.environment}/${var.aws_region}/terraform.tfstate"
    region         = "us-east-1"  # Fixed region for backend
    dynamodb_table = "terraform-locks"  # Optional: For state locking
  }
}

variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be 'dev' or 'prod'."
  }
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "example" {
  bucket = "${var.app_name}-${var.environment}-${var.aws_region}-bucket"
  tags = {
    App         = var.app_name
    Environment = var.environment
    Region      = var.aws_region
  }
}