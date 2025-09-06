terraform {
  required_providers {
    # Example: AWS provider
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the provider (example for AWS)
provider "aws" {
  region = "us-east-1"
}

# Add a resource (example: an S3 bucket)
resource "aws_s3_bucket" "example" {
  bucket = "my-s3-bucket-test"
}