variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "ami_id" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}