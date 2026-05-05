provider "aws" {
  region = "ap-south-1"
}

########################################
# S3 BUCKET
########################################
resource "aws_s3_bucket" "app_bucket" {
  bucket = "app-demo-bucket-123456789"
}

########################################
# IAM USER
########################################
resource "aws_iam_user" "app_user" {
  name = "app-user"
}

resource "aws_iam_user_login_profile" "app_user_login" {
  user                    = aws_iam_user.app_user.name
  password_reset_required = true
}

resource "aws_iam_access_key" "app_user_key" {
  user = aws_iam_user.app_user.name
}

########################################
# IAM GROUP
########################################
resource "aws_iam_group" "dev_group" {
  name = "dev-group"
}

resource "aws_iam_user_group_membership" "user_group" {
  user = aws_iam_user.app_user.name

  groups = [
    aws_iam_group.dev_group.name
  ]
}

########################################
# IAM POLICY (User/Group permissions)
########################################
resource "aws_iam_policy" "dev_policy" {
  name        = "DevPolicy"
  description = "User access policy (S3 read + EC2 describe)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets",
          "ec2:Describe*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "group_attach" {
  group      = aws_iam_group.dev_group.name
  policy_arn = aws_iam_policy.dev_policy.arn
}

########################################
# IAM ROLE FOR EC2 (S3 ACCESS ROLE)
########################################
resource "aws_iam_role" "ec2_role" {
  name = "ec2-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

########################################
# IAM POLICY FOR EC2 ROLE (S3 FULL ACCESS)
########################################
resource "aws_iam_policy" "ec2_s3_policy" {
  name = "EC2S3AccessPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.app_bucket.arn,
          "${aws_s3_bucket.app_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_role_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_s3_policy.arn
}

########################################
# INSTANCE PROFILE (Required for EC2 Role)
########################################
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

########################################
# EC2 INSTANCE
########################################
resource "aws_instance" "app_server" {
  ami           = "ami-0c2af51e265bd5e0e" # Amazon Linux (region-specific)
  instance_type = "t2.micro"

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "AppServer"
  }
}

########################################
# OUTPUTS
########################################
output "access_key_id" {
  value = aws_iam_access_key.app_user_key.id
}

output "secret_access_key" {
  value     = aws_iam_access_key.app_user_key.secret
  sensitive = true
}

output "console_password" {
  value     = aws_iam_user_login_profile.app_user_login.password
  sensitive = true
}

output "s3_bucket_name" {
  value = aws_s3_bucket.app_bucket.bucket
}

output "ec2_instance_id" {
  value = aws_instance.app_server.id
}
