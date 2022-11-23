# K8S worker (spot) nodes, all in one ASG

resource "aws_iam_role" "worker-role" {
  name                = "${var.cluster_name}-worker-nodegroup-NodeInstanceRole"
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

resource "aws_iam_instance_profile" "worker-instance-profile" {
  name = "${var.cluster_name}-worker-profile"
  role = aws_iam_role.worker-role.name
}

resource "aws_security_group" "worker-asg-sg" {
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "worker_asg_sg"
  }
}

resource "aws_security_group_rule" "controlplane-to-worker-asg" {
  type                     = "ingress"
  description              = "Allow worker nodes Kubelets and pods to receive communication from the cluster control plane"
  security_group_id        = aws_security_group.worker-asg-sg.id
  source_security_group_id = aws_security_group.eksControlPlaneSG.id
  protocol                 = "tcp"
  from_port                = 1025
  to_port                  = 65535
}

resource "aws_security_group_rule" "worker-asg-to-worker-asg" {
  type                     = "ingress"
  description              = "Allow nodes to communicate with each other"
  security_group_id        = aws_security_group.worker-asg-sg.id
  source_security_group_id = aws_security_group.worker-asg-sg.id
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 65535
}

resource "aws_security_group_rule" "service-asg-to-worker-asg" {
  type                     = "ingress"
  description              = "Allow services nodes to communicate with worker nodes"
  security_group_id        = aws_security_group.worker-asg-sg.id
  source_security_group_id = aws_security_group.services-asg-sg.id
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 65535
}

# SG in services-asg.tf
resource "aws_security_group_rule" "worker-asg-to-services-asg" {
  type                     = "ingress"
  description              = "Allow worker nodes to communicate with services nodes"
  security_group_id        = aws_security_group.services-asg-sg.id
  source_security_group_id = aws_security_group.worker-asg-sg.id
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 65535
}

resource "aws_security_group_rule" "controplane-to-worker-asg" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker-asg-sg.id
  source_security_group_id = aws_security_group.eksControlPlaneSG.id
  to_port                  = 65535
  type                     = "ingress"
}

# SG in eks-cluster.tf
resource "aws_security_group_rule" "worker-asg-to-controlplane" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eksControlPlaneSG.id
  source_security_group_id = aws_security_group.worker-asg-sg.id
  to_port                  = 443
  type                     = "ingress"
}

data "aws_ami" "ami-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.eks_version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

locals {
  worker-nodes-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh ${var.cluster_name} --use-max-pods false --kubelet-extra-args '--eviction-hard=memory.available<500Mi --eviction-soft=\"memory.available<1024Mi\" --eviction-soft-grace-period=\"memory.available=30s\" --system-reserved=memory=1.5Gi --kube-reserved=\"cpu=250m,memory=0.5Gi,ephemeral-storage=1Gi\" --node-labels=env=worker --register-with-taints=env=worker:NoSchedule'
USERDATA
}

resource "aws_launch_template" "worker-launch-config" {
  image_id               = data.aws_ami.ami-worker.id
  instance_type          = "m5.large"
  name_prefix            = "${var.cluster_name}-worker"
  vpc_security_group_ids = [aws_security_group.worker-asg-sg.id]
  user_data              = base64encode(local.worker-nodes-userdata)

  iam_instance_profile {
    name = aws_iam_instance_profile.worker-instance-profile.name
  }

  network_interfaces {
    associate_public_ip_address = false
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Not working, idk why
# resource "aws_autoscaling_group" "worker-asg" {
#   name_prefix         = "${var.cluster_name}-worker"
#   max_size            = 5
#   min_size            = 0
#   vpc_zone_identifier = var.private_subnet_ids
#   health_check_type   = "EC2"

#   mixed_instances_policy {

#     launch_template {
#       launch_template_specification {
#         launch_template_id = aws_launch_template.worker-launch-config.id
#       }


#       override {
#         instance_type = "m5.2xlarge"
#       }

#       override {
#         instance_type = "c5.large"
#       }
#     }
#   }

#   lifecycle {
#     create_before_destroy = true
#     ignore_changes        = [desired_capacity, target_group_arns]
#   }
# }
