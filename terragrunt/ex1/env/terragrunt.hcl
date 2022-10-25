# Configure S3 as a backend
remote_state {
  backend = "s3"
  config = {
    bucket = "test-s3bucket-20221025163109283700000001"
    region = "eu-central-1"
    key    = "ex1/${path_relative_to_include()}/terraform.tfstate"
    profile = "sandbox"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
