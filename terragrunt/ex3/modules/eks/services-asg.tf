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

resource "aws_iam_instance_profile" "services-instance-profile" {
  name = "${var.cluster_name}-services-profile"
  role = aws_iam_role.services-role.name
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

data "aws_ami" "ami-services" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.eks_version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

locals {
  services-nodes-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh ${var.cluster_name} --use-max-pods false --kubelet-extra-args '--eviction-hard=memory.available<500Mi --eviction-soft=\"memory.available<1024Mi\" --eviction-soft-grace-period=\"memory.available=30s\" --system-reserved=memory=1.5Gi --kube-reserved=\"cpu=250m,memory=0.5Gi,ephemeral-storage=1Gi\" --node-labels=env=services --register-with-taints=env=services:NoSchedule'
USERDATA
}

resource "aws_launch_template" "services-launch-config" {
  image_id               = data.aws_ami.ami-services.id
  instance_type          = "m5.large"
  name_prefix            = "${var.cluster_name}-services"
  vpc_security_group_ids = [aws_security_group.services-asg-sg.id]
  user_data              = base64encode(local.services-nodes-userdata)

  iam_instance_profile {
    name = aws_iam_instance_profile.services-instance-profile.name
  }

  network_interfaces {
    associate_public_ip_address = false
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "services-asg" {
  name_prefix = "${var.cluster_name}-services"
  max_size    = 5
  min_size    = 0

  launch_template {
    id      = aws_launch_template.services-launch-config.id
    version = "$Latest"
  }

  vpc_zone_identifier = var.private_subnet_ids
  health_check_type   = "EC2"

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity, target_group_arns]
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  for_each = var.lb

  autoscaling_group_name = aws_autoscaling_group.services-asg.id
  lb_target_group_arn    = aws_lb_target_group.ingresses_targetgroup[each.key].id
}
