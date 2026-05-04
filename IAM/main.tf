provider "aws" {
  region = "ap-south-1"
}

####################################
# IAM USER (Human Access)
####################################
resource "aws_iam_user" "dev_user" {
  name = "dev-user"
}

####################################
# IAM POLICY (S3 Read Only)
####################################
resource "aws_iam_policy" "s3_read_only" {
  name        = "S3ReadOnlyPolicy"
  description = "Allow read-only access to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = "*"
      }
    ]
  })
}

####################################
# ATTACH POLICY TO USER
####################################
resource "aws_iam_user_policy_attachment" "user_attach" {
  user       = aws_iam_user.dev_user.name
  policy_arn = aws_iam_policy.s3_read_only.arn
}

####################################
# IAM ROLE (For EC2)
####################################
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

####################################
# ATTACH POLICY TO ROLE
####################################
resource "aws_iam_role_policy_attachment" "role_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_read_only.arn
}

####################################
# INSTANCE PROFILE (Attach to EC2)
####################################
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

####################################
# OUTPUTS
####################################
output "iam_user_name" {
  value = aws_iam_user.dev_user.name
}

output "iam_role_name" {
  value = aws_iam_role.ec2_role.name
}

output "instance_profile" {
  value = aws_iam_instance_profile.ec2_profile.name
}
