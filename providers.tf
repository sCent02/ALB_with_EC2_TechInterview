provider "aws" {
    region = "ap-southeast-1"
}

terraform {
    backend "s3" {
        bucket          = "cambridge-exam-terraform-backend-9h9ff3ee"
        key             = "exam/terraform.tfstate"
        region          = "ap-southeast-1"
        dynamodb_table  = "cambridge-exam-terraform-locks"
    }
}