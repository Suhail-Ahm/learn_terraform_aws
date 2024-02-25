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

  # TODO:: Write for iam role creation
  iam_instance_profile = "EC2S3Role"

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("/home/suhail/Desktop/personnal/my-terra-ec2.pem")
    host        = self.public_ip
  }
  # Run provisioner to execute commands on the EC2 instance
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      "sudo apt-get update",
      "sudo apt-get install -y ruby wget",
      "sudo apt-get install -y -f",
      "cd /home/ubuntu",
      "wget https://aws-codedeploy-ca-central-1.s3.ca-central-1.amazonaws.com/latest/install",
      "chmod +x ./install",
      "sudo ./install auto"
    ]
  }

}

resource "aws_eip" "terra_eip" {
  instance = aws_instance.terra.id
  tags = {
    Name = "terra"
  }
}

# Define CodeDeploy application
resource "aws_codedeploy_app" "fastapi_deploy" {
  name             = "Fastapi"
  compute_platform = "Server"
  tags = {
    "Name" = "Terraform"
  }
}

data "aws_iam_role" "codedeploy_role" {
  name = "CodeDeployRole"
}

resource "aws_codedeploy_deployment_group" "fastapi_deploy_group" {
  app_name               = aws_codedeploy_app.fastapi_deploy.name
  deployment_group_name  = "dev"
  service_role_arn       = data.aws_iam_role.codedeploy_role.arn
  deployment_config_name = "CodeDeployDefault.OneAtATime"
  ec2_tag_filter {
    key   = "Name"
    type  = "KEY_AND_VALUE"
    value = "Terraform"
  }
}
