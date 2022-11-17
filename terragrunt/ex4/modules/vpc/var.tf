variable "cidr_block" {
  type    = string
  default = "10.216.0.0/22"
}

variable "instance_tenancy" {
  type    = string
  default = "default"
}

variable "vpc_name" {
  type = string
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones used by the VPC/Subnets"
  default     = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["10.216.1.128/25", "10.216.2.128/25", "10.216.2.0/25"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["10.216.0.128/25", "10.216.0.0/25", "10.216.1.0/25"]
}

variable "aws_vpn_gateway_amazon_side_asn" {
  type    = number
  default = 64512
}

variable "aws_customer_gateway_bgp_asn" {
  type    = number
  default = 65000
}

variable "aws_customer_gateway_ip_address" {
  type    = string
  default = "192.1.0.10"
}

variable "aws_customer_gateway_type" {
  type    = string
  default = "ipsec.1"
}

variable "aws_vpn_connection_outside_ip_address_type" {
  type    = string
  default = "PublicIpv4"
}

variable "aws_vpn_connection_type" {
  type    = string
  default = "ipsec.1"
}
