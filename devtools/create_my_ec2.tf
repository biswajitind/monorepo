provider "aws" {
    region = "us-east-1"
  }
  
  # Get current public IP address of the host running Terraform
  data "http" "current_ip" {
    url = "https://ipv4.icanhazip.com"
  }
  
  # Get current login user
  data "external" "current_user" {
    program = ["sh", "-c", "echo '{\"username\":\"'$(whoami)'\"}'"]
  }
  
  # Get the latest Amazon Linux AMI
  data "aws_ami" "amazon_linux_latest" {
    most_recent = true
    owners      = ["amazon"]
  
    filter {
      name   = "name"
      values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
  
    filter {
      name   = "virtualization-type"
      values = ["hvm"]
    }
  
    filter {
      name   = "state"
      values = ["available"]
    }
  }
  
  # Get default VPC
  data "aws_vpc" "default" {
    default = true
  }
  
  # Create security group allowing SSH from current host IP
  resource "aws_security_group" "dev_ssh_sg" {
    name_prefix = "${data.external.current_user.result.username}_dev_sg"
    description = "Security group for ${data.external.current_user.result.username} dev instance - SSH access"
    vpc_id      = data.aws_vpc.default.id
  
    ingress {
      description = "SSH from current host"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["${chomp(data.http.current_ip.response_body)}/32"]
    }
  
    egress {
      description = "All outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  
    tags = {
      Name = "${data.external.current_user.result.username}_dev_sg"
      Owner = data.external.current_user.result.username
    }
  }
  
  # Create EC2 instance
  resource "aws_instance" "user_dev" {
    ami                    = data.aws_ami.amazon_linux_latest.id
    instance_type          = "t2.micro"
    key_name              = "testkeypair"
    vpc_security_group_ids = [aws_security_group.dev_ssh_sg.id]
  
    tags = {
      Name = "${data.external.current_user.result.username}_dev"
      Owner = data.external.current_user.result.username
      Environment = "Development"
    }
  }
  
  # Outputs
  output "instance_details" {
    description = "Details of the created EC2 instance"
    value = {
      instance_id   = aws_instance.user_dev.id
      public_ip     = aws_instance.user_dev.public_ip
      public_dns    = aws_instance.user_dev.public_dns
      instance_name = aws_instance.user_dev.tags.Name
      ami_id        = aws_instance.user_dev.ami
      current_host_ip = chomp(data.http.current_ip.response_body)
    }
  }
  
  output "ssh_command" {
    description = "SSH command to connect to the EC2 instance"
    value       = "ssh -i ~/Downloads/testkeypair.pem ec2-user@${aws_instance.user_dev.public_dns}"
  }
  
  output "security_group_id" {
    description = "Security group ID created for the instance"
    value       = aws_security_group.dev_ssh_sg.id
  }
  