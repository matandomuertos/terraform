variable "cidr_block" {
  type = string
  default = "192.0.0.0/16"
}

variable "instance_tenancy" {
  type = string
  default = "default"
}

variable "vpc_name" {
  type = string
}