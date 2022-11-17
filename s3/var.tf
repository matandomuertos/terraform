variable "aws_region" {
  description = "AWS region"
  default     = "eu-central-1"
}

variable "bucket_prefix" {
  type    = string
  default = "test-s3bucket-"
}

variable "tags" {
  type = map(any)
  default = {
    environment = "DEV"
    terraform   = "true"
  }
}

variable "versioning" {
  type    = bool
  default = false
}

variable "acl" {
  type        = string
  description = "Defaults to private"
  default     = "private"
}
