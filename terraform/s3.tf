resource "aws_s3_bucket" "my_app_bucket" {
  # Bucket names must be globally unique
  bucket = "my-unique-terraform-oidc-bucket-12345"

  tags = {
    Name        = "My Terraform OIDC Bucket"
    Environment = "Dev"
  }
}