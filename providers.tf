provider "aws" {
    region = "ap-southeast-1"
}

terraform {
    backend "s3" {
        bucket          = "cambridge-exam-terraform-backend-uzab0on6"
        key             = "exam/terraform.tfstate"
        region          = "ap-southeast-1"
        dynamodb_table  = "cambridge-exam-terraform-locks"
    }
}