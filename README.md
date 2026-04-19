# ALB with EC2 Tech Interview Project

This project demonstrates the provisioning of an AWS Application Load Balancer (ALB) and two EC2 instances using Terraform, deployed via a CI/CD pipeline with GitHub Actions and OIDC authentication.

## Overview

The goal of this technical simulation is to successfully build and deploy AWS resources (ALB and EC2 instances) using Terraform through an automated CI/CD pipeline. This setup was part of a tech interview scenario at Cambridge, where specific inputs are provided via pipeline variables.

## Prerequisites

- AWS Account with appropriate permissions
- GitHub repository with Actions enabled
- Terraform installed locally for initial setup
- AWS CLI configured (optional, for local testing)

## Setup Instructions

### 1. Verify the Inputs

Before proceeding, ensure you have the following AWS resources set up in your account. **Note: The values below are dummy examples. You must create and configure your own infrastructure first using Terraform locally or via AWS Console.**

- **VPC ID**: `vpc-12345678` (Create a VPC with public subnets)
- **Subnet IDs**: `["subnet-12345678", "subnet-87654321"]` (Two public subnets in different AZs)
- **Security Group ID**: `sg-12345678` (Allow HTTP on port 80 from anywhere)
- **AMI ID**: `ami-12345678` (Amazon Linux 2 AMI)
- **Instance Profile Name**: `your-instance-profile` (IAM instance profile for EC2)

### 2. Set the Variables

Update the following variables in your GitHub repository secrets and the pipeline files:

- `AWS_ROLE_ARN`: ARN of the IAM role for OIDC
- `AWS_REGION`: Your AWS region (e.g., `ap-southeast-1`)

In the pipeline files (`.github/workflows/terraform.yml` and `terraform-destroy.yml`), replace the dummy values with your actual resource IDs.

### 3. Set Up Terraform Blocks

The Terraform configuration includes:

- `providers.tf`: AWS provider and S3 backend configuration
- `variables.tf`: Input variables
- `main.tf`: Resource definitions for ALB, Target Group, EC2 instances, and attachments
- `outputs.tf`: Output values for ALB DNS and instance IPs

Ensure all files are in the root directory.

### 4. Create CI/CD Pipeline

The project includes two GitHub Actions workflows:

- `terraform.yml`: Deploys the infrastructure on push to main branch
- `terraform-destroy.yml`: Manually destroys resources (requires confirmation)

Commit and push these files to your repository.

### 5. Run the Pipeline

- Push changes to the `main` branch to trigger the deploy pipeline.
- For destroy, go to Actions > Terraform Destroy > Run workflow, and enter `YES` for confirmation.

Monitor the pipeline logs for successful deployment.

### 6. Successfully Connect to ALB

After deployment:

- Retrieve the ALB DNS name from the pipeline outputs or Terraform outputs.
- Visit `http://<alb-dns-name>` in your browser.
- You should see responses alternating between "Hello from Instance 0" and "Hello from Instance 1".

## Architecture

- **ALB**: Distributes traffic to two EC2 instances
- **EC2 Instances**: Running Apache HTTP Server with simple HTML pages
- **Target Group**: Registers the EC2 instances for load balancing

## Notes

- This is a simulation project. Use dummy inputs as placeholders and replace with real AWS resource IDs.
- Ensure your AWS account has the necessary permissions for the resources being created.
- Costs may incur for AWS resources; monitor and clean up after testing.
- The destroy pipeline is manual to prevent accidental deletions.

## Contributing

Feel free to fork and modify for your own use cases.
