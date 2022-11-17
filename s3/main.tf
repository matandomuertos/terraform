provider "aws" {
  region                   = var.aws_region
  shared_credentials_files = ["/Users/nahuel.cassinari/.aws/credentials"]
  profile                  = "sandbox"
}

terraform {
  backend "s3" {
    bucket                  = "backup-30dayglacier"
    key                     = "./terraform-s3-test.tfstate"
    region                  = "us-east-1"
    profile                 = "sandbox"
    shared_credentials_file = "/Users/nahuel.cassinari/.aws/credentials"
  }
}
