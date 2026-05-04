provider "aws" {                       Tells Terraform: “Use AWS as the cloud provider.”
  region = "ap-south-1"                Sets region to Mumbai (ap-south-1)
}

############################
# VARIABLES
############################
variable "my_ip" {}                      A user input variable Used to restrict SSH access securely

############################
# VPC                                   Resource -tells Terraform you are creating infrastructure
############################
resource "aws_vpc" "main" {                Creates a private network inside AWS
  cidr_block           = "10.0.0.0/16"     Defines IP range for entire network
  enable_dns_support   = true              EC2 DNS names Internal service discovery
  enable_dns_hostnames = true

  tags = { Name = "prod-vpc" }            Just a label for AWS console
}

############################
# SUBNETS (PUBLIC + PRIVATE)
############################
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id     This subnet is created inside a specific VPC.
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true         “Map (assign) a public IP to every new instance launched in this subnet.”
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-south-1a"
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-south-1b"
}

############################
# INTERNET GATEWAY
############################
resource "aws_internet_gateway" "igw" {             Connects VPC → Internet
  vpc_id = aws_vpc.main.id
}

############################
# NAT GATEWAY
############################
resource "aws_eip" "nat" {         This creates a static public IP address in AWS.
  domain = "vpc"                   This Elastic IP is for use inside a VPC
}

resource "aws_nat_gateway" "nat" {    
  allocation_id = aws_eip.nat.id                This attaches the Elastic IP to NAT Gateway.
  subnet_id     = aws_subnet.public_a.id        NAT Gateway MUST be placed in a public subnet
}

############################
# ROUTE TABLES
############################
resource "aws_route_table" "public" {           You are creating a route table inside AWS VPC
  vpc_id = aws_vpc.main.id                      Attaches this route table to your VPC

  route {                                        This defines a single routing rule.
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id     It sends matched traffic to IGW GATEWAY
  }
}

resource "aws_route_table" "private" {            You are creating a route table inside AWS VPC
  vpc_id = aws_vpc.main.id                        Attaches this route table to your VPC

  route {                                         This defines a single routing rule.
    cidr_block     = "0.0.0.0/0"                  This matches ALL internet traffic
    nat_gateway_id = aws_nat_gateway.nat.id       It sends matched traffic to NAT GATEWAY
  }
}

resource "aws_route_table_association" "pub_a" {     You are creating a connection between subnet A and a route table
  subnet_id      = aws_subnet.public_a.id             Attach this route table to public subnet A”
  route_table_id = aws_route_table.public.id          Links subnet to the PUBLIC route table
}

resource "aws_route_table_association" "pub_b" {     You are creating a connection between subnet B and a route table
  subnet_id      = aws_subnet.public_b.id            Attach this route table to public subnet A”
  route_table_id = aws_route_table.public.id         Links subnet to the PUBLIC route table
}

resource "aws_route_table_association" "priv_a" {     
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "priv_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

############################
# KEY PAIR
############################
resource "aws_key_pair" "key" {                 Create an AWS EC2 Key Pair”
  key_name   = "terraform-key"                  This is the name of the key inside AWS.It is just a label in AWS
  public_key = file("~/.ssh/id_rsa.pub")        Reads your local SSH public key file,Reads file content from your system,AWS stores ONLY the public key:Only public key goes to AWS
                                                Private key stays on your machine
}

############################
# SECURITY GROUPS
############################
resource "aws_security_group" "alb_sg" {              Controls traffic to the Load Balancer,Creates firewall rules for your Application Load Balancer
  vpc_id = aws_vpc.main.id                             Places this security group inside your VPC ,Security groups are always VPC-scoped

  ingress {                                              INCOMING traffic
    from_port   = 80                                     start port
    to_port     = 80                                     end port
    protocol    = "tcp"                                  HTTP protocol
    cidr_blocks = ["0.0.0.0/0"]                          entire internet
  } 

  egress {                                               OUTGOING traffic
    from_port   = 0                                      ALB can send traffic anywhere all ports
    to_port     = 0                                      all ports
    protocol    = "-1"                                   all protocols
    cidr_blocks = ["0.0.0.0/0"]                          all destinations
  }
}

resource "aws_security_group" "ec2_sg" {               Controls traffic to the backend servers
  vpc_id = aws_vpc.main.id                             security groups belong to a VPC

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]             ONLY ALB allowed
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]                              single IP only
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

############################
# S3 BUCKET
############################
resource "aws_s3_bucket" "bucket" {
  bucket = "terraform-prod-bucket-xyz-123456"
}

############################
# AMI
############################
data "aws_ami" "amazon_linux" {                  You are querying existing AWS data, not creating anything.
  most_recent = true                             If multiple AMIs match, pick the latest one
  owners      = ["amazon"]                       Only search AMIs published by AWS itself

  filter {                                        Apply conditions to narrow down AMI search
    name   = "name"                               The AMI "Name" field in AWS
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]       Find Amazon Linux 2 AMIs, any version, for x86_64 architecture
  }
}

############################
# LAUNCH TEMPLATE
############################
resource "aws_launch_template" "lt" {                              You are defining a template for launching EC2 instances
  name_prefix   = "app-lt"                                         AWS will generate names like:
  image_id      = data.aws_ami.amazon_linux.id                     EC2 will use Amazon Linux OS image
  instance_type = "t2.micro"                                       Defines EC2 hardware size

  key_name = aws_key_pair.key.key_name                             Attach SSH key to EC2

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]         Attach firewall rules to EC2 instances

  user_data = base64encode(<<EOF                                   Script that runs automatically when EC2 starts
#!/bin/bash
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "Hello from ASG EC2 (Private Subnet)" > /var/www/html/index.html
EOF
  )
}

############################
# TARGET GROUP
############################
resource "aws_lb_target_group" "tg" {                 You are creating a Target Group for a Load Balancer
  name     = "app-tg"                                This is the name of the target group in AWS console.
  port     = 80                                       ALB will send traffic to backend servers on port 80
  protocol = "HTTP"                                  Communication between ALB and EC2 is via HTTP
  vpc_id   = aws_vpc.main.id                         Target group belongs to this VPC
}

############################
# LOAD BALANCER
############################
resource "aws_lb" "alb" {                                                   You are creating a Load Balancer in AWS
  name               = "app-alb"                                            This is the AWS-visible name of your load balancer.
  load_balancer_type = "application"                                        You are creating an Application Load Balancer (ALB)

  subnets         = [aws_subnet.public_a.id, aws_subnet.public_b.id]        ALB will be deployed in two public subnets
  security_groups = [aws_security_group.alb_sg.id]                          Attach firewall rules to ALB
}

############################
# LISTENER
############################
resource "aws_lb_listener" "listener" {                  You are creating a listener for your Load Balancer
  load_balancer_arn = aws_lb.alb.arn                     Attach this listener to your ALB
  port              = 80                                 Listener will accept traffic on HTTP port 80
  protocol          = "HTTP"                             Traffic is unencrypted HTTP

  default_action {                                           What should ALB do if no other rule matches?
    type             = "forward"                            Send traffic to a backend target group
    target_group_arn = aws_lb_target_group.tg.arn           ALB forwards traffic to this target group
  }
}

############################
# AUTO SCALING GROUP
############################
resource "aws_autoscaling_group" "asg" {                You are creating an Auto Scaling Group
  desired_capacity    = 2                               Always keep 2 EC2 instances running
  max_size            = 4                               Can scale up to 4 instances under load
  min_size            = 2                               Never go below 2 instances

  vpc_zone_identifier = [
    aws_subnet.private_a.id,                          ASG will launch EC2 instances in private subnets
    aws_subnet.private_b.id
  ]

  target_group_arns = [aws_lb_target_group.tg.arn]       Automatically register EC2 instances with ALB Target Group

  launch_template {                                     ASG uses your EC2 blueprint (Launch Template)
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }
 
  tag {                                              
    key                 = "Name"                      Each EC2 instance created will have Name=asg-instance    
    value               = "asg-instance"
    propagate_at_launch = true                        Ensures tag is applied to every new EC2 instance
  }
}

############################
# OUTPUT
############################
output "alb_dns" {                           Show me this value after deployment is complete.
  value = aws_lb.alb.dns_name                 Fetch the DNS name of your Load Balancer
}
