variable "aws_region" {
  description = "AWS region"
  default = "eu-central-1"
}

variable "cluster_name" {
  type = string
}

variable "eks_version" {
  type = string
  default = "1.22"
}

variable "control_plane_logs" {
  type        = list(string)
  # check https://docs.aws.amazon.com/en_us/eks/latest/userguide/control-plane-logs.html
  default     = ["api","audit","authenticator","controllerManager","scheduler"]
}

variable "private_subnet_ids" {
  type = list
}

variable "vpc_id" {
  type = string
}

variable "cloudwatch_logs_retention" {
  type = number
  default = 7
}