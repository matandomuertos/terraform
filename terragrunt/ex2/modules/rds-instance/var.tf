variable "aws_region" {
  description = "AWS region"
  default     = "eu-central-1"
}

variable "subnetids" {
  type = list
}

variable "rds_name" {
  type = string
}

variable "allocated_storage" {
  type = number
  default = 20
}

variable "storage_type" {
  type = string
  default = "gp2"
}

variable "engine" {
  type = string
  default = "mysql"
}

variable "engine_version" {
  type = string
  default = "8.0.28"
}

variable "instance_class" {
  type = string
  default = "db.m5.large"
}

variable "db_name" {
  type = string
  default = "testdb1"
}

variable "username" {
  type = string
}

variable "password" {
  type = string
}

variable "publicly_accessible" {
  type = bool
  default = false
}

variable "skip_final_snapshot" {
  type = bool
  default = true
}