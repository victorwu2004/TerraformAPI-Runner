# 1. Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

# 2. Create the OIDC identity provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1", # GitHub's OIDC thumbprint (verify this)
  ]
}

# 3. Create an IAM role with a trust policy for OIDC
resource "aws_iam_role" "github_actions_role" {
  name = "GitHubActionsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com",
            "token.actions.githubusercontent.com:sub" = "repo:victorwu2004/TerraformAPI-Runner:ref:refs/heads/main" # Restrict to specific repo and branch
          }
        }
      }
    ]
  })
}

# 4. Attach a policy to the IAM role
resource "aws_iam_role_policy" "github_actions_policy" {
  name = "GitHubActionsPolicy"
  role = aws_iam_role.github_actions_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = [
          "arn:aws:s3:::terraform-S3bucket-test",
          "arn:aws:s3:::terraform-S3bucket-test/*"
        ]
      }
    ]
  })
}

# 5. (Optional) Output the IAM role ARN for use in GitHub Actions
output "role_arn" {
  value = aws_iam_role.github_actions_role.arn
}