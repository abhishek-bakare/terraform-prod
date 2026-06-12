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
resource "aws_subnet" "my_pub_subnet1" {
  vpc_id                  = aws_vpc.aws_vpc_myvpc.id
  cidr_block              = var.pub_subnet_cidr_1
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name        = "${var.vpc_name}-public-subnet-1"
    Environment = var.vpc_env
    Terraform   = "true"
  }
}

resource "aws_subnet" "my_pub_subnet2" {
  vpc_id                  = aws_vpc.aws_vpc_myvpc.id
  cidr_block              = var.pub_subnet_cidr_2
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags = {
    Name        = "${var.vpc_name}-public-subnet-2"
    Environment = var.vpc_env
    Terraform   = "true"
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
    "kubernetes.io/role/internal-elb"        = "1"
    "kubernetes.io/cluster/practice-cluster" = "shared"
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
    "kubernetes.io/role/internal-elb"        = "1"
    "kubernetes.io/cluster/practice-cluster" = "shared"
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

#security groups for public subnet
resource "aws_security_group" "sg_public" {
  vpc_id      = aws_vpc.aws_vpc_myvpc.id
  name        = "${var.vpc_name}-pub-sg"
  description = "Allow required rules"
  tags = {
    Name        = "${var.vpc_name}-pub-sg"
    Environment = var.vpc_env
    Terraform   = "true"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}

#sg for pvt subnet
resource "aws_security_group" "sg_private" {
  vpc_id      = aws_vpc.aws_vpc_myvpc.id
  name        = "${var.vpc_name}-sg-private"
  description = "SGs for pvt subnets"
  tags = {
    Name        = "${var.vpc_name}-pvt-sg"
    Environment = var.vpc_env
    Terraform   = "true"
  }

  ingress {
    protocol        = "-1"
    from_port       = 0
    to_port         = 0
    security_groups = [aws_security_group.sg_public.id] #allowing only if it come from sg public
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#sg for db
resource "aws_security_group" "sg_database" {
  vpc_id      = aws_vpc.aws_vpc_myvpc.id
  name        = "${var.vpc_name}-sg-database"
  description = "This is for DB"
  tags = {
    Name        = "${var.vpc_name}-pvt-sg"
    Environment = var.vpc_env
    Terraform   = "true"
  }

  ingress {
    protocol        = "tcp"
    from_port       = 5432
    to_port         = 5432
    security_groups = [aws_security_group.sg_private.id] #allowing only if it come from sg pvt subnet
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [aws_vpc.aws_vpc_myvpc.cidr_block] # Only allow talk inside our VPC
  }

}