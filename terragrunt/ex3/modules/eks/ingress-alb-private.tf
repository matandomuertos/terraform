# Part of listener + cert
# locals {
#   cert-list = flatten([
#     for c in aws_acm_certificate.cert : [
#       for l in aws_lb_listener.lb_listener_https : {
#         certificate   = c.arn
#         arn = l.arn
#       }
#     ]
#   ])
# }

# should this be only one SG? hmmm
resource "aws_security_group" "lb_sg" {
  name   = "allow_tls"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lb-sg"
  }
}

resource "aws_lb" "lb" {
  for_each = var.lb

  name                       = substr(each.key, 0, 32)
  internal                   = each.value["internal"]
  load_balancer_type         = "application"
  idle_timeout               = each.value["idle_timeout"] #min 1 / max 4000
  security_groups            = [aws_security_group.lb_sg.id]
  subnets                    = each.value["subnets"]
  enable_deletion_protection = each.value["enable_deletion_protection"]

  #   I didn't create any S3 for this
  #   access_logs {
  #     bucket  = aws_s3_bucket.lb_logs.bucket
  #     prefix  = each.value["name"]
  #     enabled = each.value["access_logs_enabled"]
  #   }

  tags = {
    Name                                        = substr(each.key, 0, 32),
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

resource "aws_lb_target_group" "ingresses_targetgroup" {
  for_each = var.lb

  name     = substr("${each.key}-tg", 0, 32)
  port     = each.value["aws_lb_target_group_port"]
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/healthz"
    port                = each.value["aws_lb_target_group_port"]
    healthy_threshold   = 4
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
    matcher             = 200
  }

  tags = {
    Name                                        = substr("${each.key}-tg", 0, 32),
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

resource "aws_lb_listener" "lb_listener_http" {
  for_each = aws_lb.lb

  load_balancer_arn = each.value["arn"]
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_302"
      host        = "#{host}"
      path        = "/#{path}"
      query       = "#{query}"
    }
  }
}

# It's not possible to create htts listeners because the certs are not real, with real certs, this should work fine :D 
# resource "aws_lb_listener" "lb_listener_https" {
#   for_each = var.lb

#   load_balancer_arn = aws_lb.lb[each.key].arn
#   port = "443"
#   protocol = "HTTPS"
#   ssl_policy = "ELBSecurityPolicy-2016-08"
#   certificate_arn = aws_acm_certificate.cert[keys(var.certificates)[0]].arn

#   default_action {
#     type = "forward"
#     target_group_arn = aws_lb_target_group.ingresses_targetgroup[each.key].arn
#   }
# }

# resource "aws_lb_listener_certificate" "lb_additional_certs_https" {
#   count = length(local.cert-list)

#   listener_arn    = local.cert-list[count.index].arn
#   certificate_arn = local.cert-list[count.index].certificate
# }
