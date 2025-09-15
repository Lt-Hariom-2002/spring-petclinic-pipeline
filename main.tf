provider "aws" {
  region = "us-east-1"
}

# Artifact Server
resource "aws_instance" "artifact_server" {
  ami             = "ami-0360c520857e3138f"   # Ubuntu AMI
  instance_type   = "t3.micro"
  security_groups = ["launch-wizard-1"]       # Use your existing SG
  key_name        = "hariom"                  # Your key pair name

  tags = {
    Name = "artifact-server"
  }
}

# Application Server
resource "aws_instance" "app_server" {
  ami             = "ami-0360c520857e3138f"
  instance_type   = "t3.micro"
  security_groups = ["launch-wizard-1"]
  key_name        = "hariom"

  tags = {
    Name = "app-server"
  }
}

# Outputs
output "artifact_server_ip" {
  value = aws_instance.artifact_server.public_ip
}

output "app_server_ip" {
  value = aws_instance.app_server.public_ip
}
