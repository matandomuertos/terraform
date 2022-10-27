# Generate AWS provider
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
  provider "aws" {
    region = var.aws_region
    shared_credentials_files = var.aws_shared_credentials_files
    profile = var.aws_profile
  }
EOF
}


# Configure S3 as a backend
remote_state {
  backend = "s3"
  config = {
    bucket = "test-s3bucket-20221025163109283700000001"
    region = "eu-central-1"
    key = "ex4/${path_relative_to_include()}/terraform.tfstate"
    profile = "sandbox"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}