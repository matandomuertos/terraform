variable "aws_region" {
  description = "AWS region"
  default = "eu-central-1"
}

variable "instance_type" {
  description = "The instance type to use"
  type = string
  default = "t2.micro"
}

variable "instance_name" {
  description = "The name to use for the instance"
  type = string
}

variable "ami" {
  type = string
  default = "ami-070b208e993b59cea"
}

variable "subnetid" {
  type = string
}
