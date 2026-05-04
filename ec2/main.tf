provider "aws" {
  region = "ap-south-1" # change if needed
}

########################
# Key Pair (optional)
########################
resource "aws_key_pair" "deployer" {
  key_name   = "terraform-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

########################
# Security Group
########################
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-security-group"
  description = "Allow SSH and HTTP"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["your_IP/32"] 
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["your_IP/32"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

########################
# EC2 Instance
########################
resource "aws_instance" "web" {
  ami           = "ami-0f5ee92e2d63afc18" # Amazon Linux 2 (update per region)
  instance_type = "t2.micro"

  key_name        = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.ec2_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello from Terraform EC2" > /var/www/html/index.html
              EOF

  tags = {
    Name = "Terraform-EC2"
  }
}
