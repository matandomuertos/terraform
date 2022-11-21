# K8S services and ingress nodes, all in one ASG

resource "aws_iam_role" "services-role" {
  name                = "${var.cluster_name}-services-nodegroup-NodeInstanceRole"
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy", "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy", "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"]
  assume_role_policy  = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "services-policy" {
  name   = "PolicyAutoScaling"
  role   = aws_iam_role.services-role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "ec2:DescribeLaunchTemplateVersions",
                "ec2:DescribeSpotInstanceRequests"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_security_group" "services-asg-sg" {
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "services_asg_sg"
  }
}

resource "aws_security_group_rule" "controlplane-to-service-asg" {
  type                     = "ingress"
  description              = "Allow service nodes Kubelets and pods to receive communication from the cluster control plane"
  security_group_id        = aws_security_group.services-asg-sg.id
  source_security_group_id = aws_security_group.eksControlPlaneSG.id
  protocol                 = "tcp"
  from_port                = 1025
  to_port                  = 65535
}

resource "aws_security_group_rule" "service-asg-e-to-service-asg" {
  type                     = "ingress"
  description              = "Allow node to communicate with each other"
  security_group_id        = aws_security_group.services-asg-sg.id
  source_security_group_id = aws_security_group.services-asg-sg.id
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 65535
}

resource "aws_security_group_rule" "controplane-to-service-asg" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.services-asg-sg.id
  source_security_group_id = aws_security_group.eksControlPlaneSG.id
  to_port                  = 65535
  type                     = "ingress"
}

# SG in eks-cluster.tf
resource "aws_security_group_rule" "service-asg-to-controlplane" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eksControlPlaneSG.id
  source_security_group_id = aws_security_group.services-asg-sg.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "albs-to-service-asg" {
  description              = "Allow ALB to communicate with nodes"
  from_port                = 31000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.services-asg-sg.id
  source_security_group_id = aws_security_group.lb_sg.id
  to_port                  = 31001
  type                     = "ingress"
}


## continue creating the ASG
