provider "aws" {
  region = "ap-south-1"
}

data "aws_vpc" "default_vpc" {
  default = true
}

output "default_vpc_id" {
  value = data.aws_vpc.default_vpc.id
}

# Retrieve the latest Ubuntu AMI matching the specified criteria.
data "aws_ami" "latest_ubuntu_ami" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20231207"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

output "ubuntu_ami_id" {
  value = data.aws_ami.latest_ubuntu_ami.image_id
}


resource "aws_security_group" "website_security_group" {
  name        = "website_security_group"
  description = "Security group for website"

  vpc_id = data.aws_vpc.default_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "terra" {
  ami                    = data.aws_ami.latest_ubuntu_ami.image_id
  instance_type          = "t2.micro"
  key_name               = "my-terra-ec2"
  vpc_security_group_ids = [aws_security_group.website_security_group.id]

  tags = {
    Name = "Terraform"
  }

  lifecycle {
    precondition {
      condition     = data.aws_ami.latest_ubuntu_ami.architecture == "x86_64"
      error_message = "The selected AMI must be for the x86_64 architecture."
    }
  }

  associate_public_ip_address = true
}

resource "aws_eip" "terra_eip" {
  instance = aws_instance.terra.id
  tags = {
    Name = "terra"
  }
}
