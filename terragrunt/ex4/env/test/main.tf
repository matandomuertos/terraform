module "vpc" {
  source = "./../../modules/vpc"

  vpc_name = var.vpc_name
}