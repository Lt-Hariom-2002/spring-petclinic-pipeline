provider "aws" {
  region = "us-east-1"
}
resource "aws_instance" "tomcat_server" {
  ami           = "ami-0360c520857e3138f"
  instance_type = "t3.micro"
  security_groups = ["launch-wizard-1"]  # Reference the existing security group
  key_name      = "hariom"
}



output  "tomcat_server_ip" {
  value = aws_instance.tomcat_server.public_ip
}
