module "eks" {
  source = "./../../modules/eks"

  cluster_name = var.cluster_name
  private_subnet_ids = var.private_subnet_ids
  vpc_id = var.vpc_id
  service_ipv4_cidr = var.service_ipv4_cidr
}