# Terraform AWS EC2 Deployment

This repository contains Terraform configuration files to deploy an EC2 instance on AWS.

## Prerequisites

Before you begin, ensure you have the following installed:

- [Terraform](https://www.terraform.io/downloads.html)
- [AWS CLI](https://aws.amazon.com/cli/)

You'll also need an AWS account and appropriate IAM permissions to create resources.

## Getting Started

1. Clone this repository:

    ```bash
    git clone https://github.com/your-username/terraform-aws-ec2-deployment.git
    ```

2. Navigate to the cloned directory:

    ```bash
    cd terraform-aws-ec2-deployment
    ```

3. Initialize Terraform:

    ```bash
    terraform init
    ```

## Configuration

Update `variables.tf` file with your desired configurations such as instance type, AMI ID, key pair, etc.

## Deployment

1. Review the Terraform plan:

    ```bash
    terraform plan
    ```

2. If the plan looks good, apply it:

    ```bash
    terraform apply
    ```

    You'll be prompted to confirm the action. Enter `yes` to proceed.

## Accessing the Instance

Once the deployment is complete, you can access the instance using SSH.

```bash
ssh -i /path/to/your/key.pem ec2-user@<instance-public-ip>
