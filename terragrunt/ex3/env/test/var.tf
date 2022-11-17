variable "aws_region" {
  description = "AWS region"
  default     = "eu-central-1"
}

variable "cluster_name" {
  type = string
}

variable "eks_version" {
  type    = string
  default = "1.22"
}

variable "public_access_cidrs" {
  type    = list(string)
  default = ["1.1.1.1/32", "2.2.2.2/32"]
}

variable "coredns_addon_version" {
  type    = string
  default = "v1.8.7-eksbuild.1"
}

variable "kubeproxy_addon_version" {
  type    = string
  default = "v1.22.6-eksbuild.1"
}

variable "ip_family" {
  type    = string
  default = "ipv4"
}

variable "service_ipv4_cidr" {
  type = string
}

variable "control_plane_logs" {
  type = list(string)
  # check https://docs.aws.amazon.com/en_us/eks/latest/userguide/control-plane-logs.html
  default = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "private_subnet_ids" {
  type = list(any)
}

variable "vpc_id" {
  type = string
}

variable "cloudwatch_logs_retention" {
  type    = number
  default = 7
}
