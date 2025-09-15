# 1. Create the OIDC Identity Provider for GitHub
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # Use the official thumbprint
}

# 2. Define the Trust Policy for the IAM Role
# This policy allows entities from a specific GitHub repo/branch to assume the role.
data "aws_iam_policy_document" "github_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # Condition: Only allow from your specific repository and main branch
    # IMPORTANT: Change this to your GitHub username and repository name
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:your-github-username/your-repo-name:ref:refs/heads/main"]
    }
  }
}

# 3. Define the Permissions Policy
# This policy grants the necessary permissions to manage the S3 bucket.
data "aws_iam_policy_document" "s3_management_policy" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      aws_s3_bucket.my_app_bucket.arn,
      "${aws_s3_bucket.my_app_bucket.arn}/*",
    ]
  }
}

# 4. Create the IAM Role and attach the policies
resource "aws_iam_role" "github_actions_role" {
  name               = "github-actions-s3-role"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role_policy.json
}

resource "aws_iam_policy" "s3_policy" {
  name   = "s3-management-policy"
  policy = data.aws_iam_policy_document.s3_management_policy.json
}

resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}

# Output the Role ARN to use it in the GitHub workflow
output "iam_role_arn" {
  value       = aws_iam_role.github_actions_role.arn
  description = "The ARN of the IAM role for GitHub Actions."
}