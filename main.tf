# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Create the OIDC identity provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1", # GitHub's OIDC thumbprint (as of latest documentation)
  ]
}

# Create an IAM role with a trust policy for OIDC
resource "aws_iam_role" "github_actions_role" {
  name = "GitHubActionsEC2Role"

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
            "token.actions.githubusercontent.com:sub" = "repo:victorwu2004/TerraformAPI-Runner:ref:refs/heads/main" # Replace with your repo
          }
        }
      }
    ]
  })
}

# Attach a policy to the IAM role for EC2 permissions
resource "aws_iam_role_policy" "github_actions_ec2_policy" {
  name = "GitHubActionsEC2Policy"
  role = aws_iam_role.github_actions_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:RunInstances",
          "ec2:DescribeInstances",
          "ec2:TerminateInstances",
          "ec2:CreateTags"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = "iam:PassRole",
        Resource = aws_iam_role.github_actions_role.arn
      }
    ]
  })
}

# Create a security group for the EC2 instance
resource "aws_security_group" "instance_sg" {
  name        = "ec2-instance-sg"
  description = "Security group for EC2 instance"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH (restrict in production)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an EC2 instance
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI (us-east-1, update as needed)
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance_sg.name]

  tags = {
    Name = "GitHubActionsEC2"
  }
}

# Output the IAM role ARN for use in GitHub Actions
output "role_arn" {
  value = aws_iam_role.github_actions_role.arn
}