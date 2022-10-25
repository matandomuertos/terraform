# EKS Cluster
resource "aws_eks_cluster" "eksCluster" {
  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKSVPCResourceController,
    aws_cloudwatch_log_group.CloudWatchLogsRetentionCluster,
  ]

  name = var.cluster_name
  role_arn = aws_iam_role.eksIAMRole.arn
  version = var.eks_version
  enabled_cluster_log_types = var.control_plane_logs

  vpc_config {
    security_group_ids = [aws_security_group.eksControlPlaneSG.id]
    subnet_ids = var.private_subnet_ids
    endpoint_private_access = "true"
    endpoint_public_access = "true"
  }
}

# EKS IAM Role
resource "aws_iam_role" "eksIAMRole" {
  name = "eks-${var.cluster_name}-IAMRole"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.eksIAMRole.name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role = aws_iam_role.eksIAMRole.name
}

# Control Plane Security Group
resource "aws_security_group" "eksControlPlaneSG" {
  description = "EKS Control Plane Security Group"
  vpc_id = var.vpc_id

  tags = {
    Name = "eks-${var.cluster_name}-ControlPlaneSG"
  }
}

# CloudWatch Logs retention (I should write the same to access-logs, addons, dataplane and host too but I'm lazy)
resource "aws_cloudwatch_log_group" "CloudWatchLogsRetentionCluster" {
  name = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cloudwatch_logs_retention
}