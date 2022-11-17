# EKS Add-ons
resource "aws_eks_addon" "kube-proxy" {
  depends_on = [
    aws_eks_cluster.eksCluster
  ]

  cluster_name      = aws_eks_cluster.eksCluster.name
  addon_name        = "kube-proxy"
  addon_version     = var.kubeproxy_addon_version
  resolve_conflicts = "OVERWRITE"
}

# resource "aws_eks_addon" "coredns" {
#   depends_on = [
#     aws_eks_cluster.eksCluster
#   ]

#   cluster_name = aws_eks_cluster.eksCluster.name
#   addon_name = "coredns"
#   addon_version = var.coredns_addon_version
#   resolve_conflicts = "OVERWRITE"
# }
