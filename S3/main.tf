provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "my-terraform-demo-bucket-123456"

  tags = {
    Name        = "terraform-s3"
    Environment = "dev"
  }
}
