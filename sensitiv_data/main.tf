# Provider (example: AWS)
provider "aws" {
  region = "ap-south-1"
}

# -----------------------------
# Sensitive Variable
# -----------------------------
variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# -----------------------------
# Example Resource (RDS)
# -----------------------------
resource "aws_db_instance" "example" {
  identifier        = "mydb-instance"
  engine            = "mysql"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  username = "admin"

  # Sensitive value used here
  password = var.db_password

  skip_final_snapshot = true
}

# -----------------------------
# Output (Masked)
# -----------------------------
output "db_endpoint" {
  value = aws_db_instance.example.endpoint
}

output "db_password_output" {
  value     = var.db_password
  sensitive = true
}
