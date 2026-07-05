#creating VPC
resource "aws_vpc" "aws_vpc_myvpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name        = "${var.vpc_name}-vpc"
    Environment = var.vpc_env
    Terraform   = "true"
  }
}

#fetching available AZ in region
data "aws_availability_zones" "available" {
  state = "available"
}

#crating IGW
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.aws_vpc_myvpc.id
  tags = {
    Name        = "${var.vpc_name}-igw"
    Environment = var.vpc_env
    Terraform   = "true"
  }
}

#Creating public subnets for VPC
# checkov:skip=CKV_AWS_130
resource "aws_subnet" "my_pub_subnet1" {
  vpc_id                  = aws_vpc.aws_vpc_myvpc.id
  cidr_block              = var.pub_subnet_cidr_1
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name        = "${var.vpc_name}-public-subnet-1"
    Environment = var.vpc_env
    Terraform   = "true"
    "kubernetes.io/role/elb" = "1"    # added for internet-facing LB's used by LBC
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# checkov:skip=CKV_AWS_130
resource "aws_subnet" "my_pub_subnet2" {
  vpc_id                  = aws_vpc.aws_vpc_myvpc.id
  cidr_block              = var.pub_subnet_cidr_2
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags = {
    Name        = "${var.vpc_name}-public-subnet-2"
    Environment = var.vpc_env
    Terraform   = "true"
    "kubernetes.io/role/elb" = "1"     # added for internet-facing LB's used by LBC
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

#route table
resource "aws_route_table" "vpc_route_table_pub" {
  vpc_id = aws_vpc.aws_vpc_myvpc.id
  tags = {
    Name        = "${var.vpc_name}-vpc-route-table"
    Environment = var.vpc_env
    Terraform   = "true"
  }
}

resource "aws_route" "vpc_public_route" {
  route_table_id         = aws_route_table.vpc_route_table_pub.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
  depends_on             = [aws_internet_gateway.my_igw]
}

#associating pub subnets
resource "aws_route_table_association" "associating_my_pub_subnet1" {
  #loop over defined subnets
  for_each = {
    subnet1 = aws_subnet.my_pub_subnet1.id,
    subnet2 = aws_subnet.my_pub_subnet2.id
  }
  route_table_id = aws_route_table.vpc_route_table_pub.id
  subnet_id      = each.value #dynamically assigns the subnet ID on each loop
  depends_on     = [aws_subnet.my_pub_subnet1, aws_route_table.vpc_route_table_pub]
}

#creating eip for nat gw
resource "aws_eip" "eip_for_nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.my_igw]
  tags = {
    Name        = "${var.vpc_name}-eip"
    Environment = var.vpc_env
    Terraform   = "true"
  }
}

#creating NAT GW
resource "aws_nat_gateway" "my_nat_gw" {
  allocation_id = aws_eip.eip_for_nat.id
  #putting natgw in public subnet
  subnet_id  = aws_subnet.my_pub_subnet1.id
  depends_on = [aws_eip.eip_for_nat, aws_internet_gateway.my_igw]
}

#private subnets
resource "aws_subnet" "my_pvt_subnet1" {
  vpc_id            = aws_vpc.aws_vpc_myvpc.id
  cidr_block        = var.pvt_subnet_cidr_1
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name                                     = "${var.vpc_name}-private-subnet-1"
    Environment                              = var.vpc_env
    Terraform                                = "true"
    "kubernetes.io/role/internal-elb"        = "1"     # added for internal LB's used by LBC
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "karpenter.sh/discovery" = var.cluster_name        # used by Karp for launching nodes
  }
}

resource "aws_subnet" "my_pvt_subnet2" {
  vpc_id            = aws_vpc.aws_vpc_myvpc.id
  cidr_block        = var.pvt_subnet_cidr_2
  availability_zone = data.aws_availability_zones.available.names[2]
  tags = {
    Name                                     = "${var.vpc_name}-private-subnet-2"
    Environment                              = var.vpc_env
    Terraform                                = "true"
    "kubernetes.io/role/internal-elb"        = "1"    # added for internal LB's used by LBC
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "karpenter.sh/discovery" = var.cluster_name       # used by Karp for launching nodes
  }
}

#aws route table for pvt subnets
resource "aws_route_table" "vpc_route_table_pvt" {
  vpc_id = aws_vpc.aws_vpc_myvpc.id
  tags = {
    Name        = "${var.vpc_name}-aws-route-table-pvt"
    Environment = var.vpc_env
    Terraform   = "true"
  }
}

#aws route
resource "aws_route" "vpc_private_route" {
  route_table_id         = aws_route_table.vpc_route_table_pvt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.my_nat_gw.id
  depends_on             = [aws_route_table.vpc_route_table_pvt]
}

#association of routes to pvt subnets
resource "aws_route_table_association" "associating_my_pvt_subnet1" {
  route_table_id = aws_route_table.vpc_route_table_pvt.id
  #loop over defined subnets
  for_each = {
    subnet1 = aws_subnet.my_pvt_subnet1.id,
    subnet2 = aws_subnet.my_pvt_subnet2.id
  }
  subnet_id  = each.value #dynamically assigns the subnet ID on each loop
  depends_on = [aws_internet_gateway.my_igw]
}



#NACl for public subnet
resource "aws_network_acl" "public_nacl" {
  vpc_id = aws_vpc.aws_vpc_myvpc.id
  for_each = {
    pub_subnet1 = aws_subnet.my_pub_subnet1.id,
    pub_subnet2 = aws_subnet.my_pub_subnet2.id
  }
  subnet_ids = [each.value]

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 101
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "udp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # ADD THIS: Allow ICMP (For Ping replies)
  ingress {
    protocol   = "icmp"
    rule_no    = 140
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
    icmp_type  = -1 # Allows all ICMP types
    icmp_code  = -1 # Allows all ICMP codes
  }

  #allowing all traffic out
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

