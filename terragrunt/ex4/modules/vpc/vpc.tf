# VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block
  instance_tenancy = var.instance_tenancy

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_ssm_parameter" "vpcIDParameter" {
  name = "/test/vpc/id"
  type = "String"
  value = aws_vpc.vpc.id
}

# resource "aws_cloudwatch_log_group" "cloudWatchLogsGroupVPC" {
#   name = "/aws/eks/${var.vpc_name}/cluster"
#   retention_in_days = var.cloudwatch_logs_retention
# }

# resource "aws_flow_log" "flowLogsVPC" {
#   iam_role_arn    = aws_iam_role.example.arn
#   log_destination = aws_cloudwatch_log_group.example.arn
#   traffic_type    = "ALL"
#   vpc_id          = aws_vpc.example.id
# }

# Public Subnets
resource "aws_subnet" "publicSubnets" {
  count = length(var.public_subnet_cidrs)

  vpc_id = aws_vpc.vpc.id
  cidr_block = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.availability_zones, count.index)
  
  tags = {
    Name = "Public Subnet ${count.index + 1}"
  }
}

# Private Subnets
resource "aws_subnet" "privateSubnets" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.vpc.id
  cidr_block = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name = "Private Subnet ${count.index + 1}"
  }
}

# Internet GateWay
resource "aws_internet_gateway" "internetGateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_name}-GW"
  }
}

# Public Route tables
resource "aws_route_table" "publicRouteTable" {
  count = length(var.public_subnet_cidrs)

  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Public Route Table ${count.index + 1} (${var.vpc_name})"
  }
}

# Private Route tables
resource "aws_route_table" "privateRouteTable" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Private Route Table ${count.index + 1} (${var.vpc_name})"
  }
}

# Public Route tables association
resource "aws_route_table_association" "publicRouteTableAssociation" {
  count = length(var.public_subnet_cidrs)

  subnet_id = aws_subnet.publicSubnets[count.index].id
  route_table_id = aws_route_table.publicRouteTable[count.index].id
}

# Private Route tables association
resource "aws_route_table_association" "privateRouteTableAssociation" {
  count = length(var.private_subnet_cidrs)

  subnet_id = aws_subnet.privateSubnets[count.index].id
  route_table_id = aws_route_table.privateRouteTable[count.index].id
}

# Elastic IPs (used by NATGateway)
resource "aws_eip" "elasticIP" {
  count = length(var.public_subnet_cidrs)

  tags = {
    Name = "Elastic IP ${count.index + 1} (${var.vpc_name})"
  }
}

# NAT Gateways
resource "aws_nat_gateway" "NATGateway" {
  count = length(var.public_subnet_cidrs)

  allocation_id = aws_eip.elasticIP[count.index].id
  subnet_id = aws_subnet.publicSubnets[count.index].id

  tags = {
    Name = "NAT Gateway ${count.index + 1} (${var.vpc_name})"
  }
}

## Client connection ##

# Customer Gateway
resource "aws_customer_gateway" "site1" {
  bgp_asn = var.aws_customer_gateway_bgp_asn
  ip_address = var.aws_customer_gateway_ip_address
  type = var.aws_customer_gateway_type

  tags = {
    Name = "site1 Gateway (${var.vpc_name})"
  }
}

# VPN Gateway
resource "aws_vpn_gateway" "VPNGateway" {
  vpc_id = aws_vpc.vpc.id
  amazon_side_asn = var.aws_vpn_gateway_amazon_side_asn
  tags = {
    Name = "VPN Gateway (${var.vpc_name})"
  }
}

# Attach VPN Gateway to VPC
resource "aws_vpn_gateway_attachment" "VPNAttachToVPC" {
  vpc_id = aws_vpc.vpc.id
  vpn_gateway_id = aws_vpn_gateway.VPNGateway.id
}

# Create vpn connection: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_connection

## Routes ##

# Allow internet access to public subnets
resource "aws_route" "IGWPublicSubnetRoute" {
  count = length(var.public_subnet_cidrs)

  route_table_id = aws_route_table.publicRouteTable[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.internetGateway.id
}

# Allow private subnets to access internet
resource "aws_route" "NATPrivateSubnetRoute" {
  count = length(var.private_subnet_cidrs)

  route_table_id = aws_route_table.privateRouteTable[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.NATGateway[count.index].id
}

# Allow private subnets to access network in customer site (VPN)
resource "aws_route" "VPNPrivateSubnetRoute" {
  count = length(var.private_subnet_cidrs)

  route_table_id = aws_route_table.privateRouteTable[count.index].id
  destination_cidr_block = "192.0.0.0/8"
  gateway_id = aws_vpn_gateway.VPNGateway.id
}