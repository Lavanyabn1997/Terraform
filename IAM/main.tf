provider "aws" {
  region = "ap-south-1"
}

############################################
# S3 BUCKET
############################################
resource "aws_s3_bucket" "app_bucket" {
  bucket = "iam-complete-demo-bucket-987654321"
}

############################################
# IAM USER (Human Access)
############################################
resource "aws_iam_user" "dev_user" {
  name = "dev-user"
}

resource "aws_iam_user_login_profile" "dev_user_login" {
  user                    = aws_iam_user.dev_user.name
  password_reset_required = true
}

resource "aws_iam_access_key" "dev_user_key" {
  user = aws_iam_user.dev_user.name
}

############################################
# IAM GROUP
############################################
resource "aws_iam_group" "dev_group" {
  name = "dev-group"
}

resource "aws_iam_user_group_membership" "user_group" {
  user = aws_iam_user.dev_user.name

  groups = [
    aws_iam_group.dev_group.name
  ]
}

############################################
# IAM POLICY (User/Group Permissions)
############################################
resource "aws_iam_policy" "user_policy" {
  name        = "UserGeneralPolicy"
  description = "Allow basic AWS read access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "s3:ListAllMyBuckets"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "group_attach" {
  group      = aws_iam_group.dev_group.name
  policy_arn = aws_iam_policy.user_policy.arn
}

############################################
# IAM ROLE (for EC2)
############################################
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

############################################
# IAM POLICY FOR EC2 ROLE (S3 ACCESS)
############################################
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

resource "aws_iam_role_policy_attachment" "role_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_s3_policy.arn
}

############################################
# INSTANCE PROFILE (CONNECT ROLE TO EC2)
############################################
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

############################################
# EC2 INSTANCE
############################################
resource "aws_instance" "app_server" {
  ami           = "ami-0c2af51e265bd5e0e"
  instance_type = "t2.micro"

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "IAM-Complete-Server"
  }
}

############################################
# OUTPUTS
############################################
output "user_access_key" {
  value = aws_iam_access_key.dev_user_key.id
}

output "user_secret_key" {
  value     = aws_iam_access_key.dev_user_key.secret
  sensitive = true
}

output "console_password" {
  value     = aws_iam_user_login_profile.dev_user_login.password
  sensitive = true
}

output "s3_bucket" {
  value = aws_s3_bucket.app_bucket.bucket
}

output "ec2_id" {
  value = aws_instance.app_server.id
}
