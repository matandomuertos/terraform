# Provider
variable "aws_region" {
  type = string
  default = "eu-north-1"
}

variable "aws_shared_credentials_files" {
  type = list(string)
  default = ["/Users/nahuel.cassinari/.aws/credentials"]
}

variable "aws_profile" {
  type = string
  default = "sandbox"
}

# VPC Module
variable "vpc_name" {
  type = string
}