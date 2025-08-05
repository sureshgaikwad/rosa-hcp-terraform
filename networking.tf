resource "aws_vpc" "cluster_vpc" {
  count = local.private_cluster ? 1 : 0

  cidr_block           = var.machine_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-vpc"
  })
}

resource "aws_internet_gateway" "cluster_igw" {
  count = local.private_cluster ? 1 : 0

  vpc_id = aws_vpc.cluster_vpc[0].id

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-igw"
  })
}

# Public subnets for NAT gateways
resource "aws_subnet" "public_subnets" {
  count = local.private_cluster ? length(var.availability_zones) : 0

  vpc_id                  = aws_vpc.cluster_vpc[0].id
  cidr_block              = cidrsubnet(var.machine_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-public-subnet-${count.index + 1}"
  })
}

# Private subnets for the cluster
resource "aws_subnet" "private_subnets" {
  count = local.private_cluster ? length(var.availability_zones) : 0

  vpc_id            = aws_vpc.cluster_vpc[0].id
  cidr_block        = cidrsubnet(var.machine_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-private-subnet-${count.index + 1}"
  })
}

# Elastic IPs for NAT gateways
resource "aws_eip" "nat_eips" {
  count = local.private_cluster ? length(var.availability_zones) : 0

  domain     = "vpc"
  depends_on = [aws_internet_gateway.cluster_igw]

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-nat-eip-${count.index + 1}"
  })
}

# NAT gateways
resource "aws_nat_gateway" "nat_gateways" {
  count = local.private_cluster ? length(var.availability_zones) : 0

  allocation_id = aws_eip.nat_eips[count.index].id
  subnet_id     = aws_subnet.public_subnets[count.index].id
  depends_on    = [aws_internet_gateway.cluster_igw]

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-nat-gateway-${count.index + 1}"
  })
}

# Route table for public subnets
resource "aws_route_table" "public_rt" {
  count = local.private_cluster ? 1 : 0

  vpc_id = aws_vpc.cluster_vpc[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cluster_igw[0].id
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-public-rt"
  })
}

# Route table associations for public subnets
resource "aws_route_table_association" "public_rta" {
  count = local.private_cluster ? length(var.availability_zones) : 0

  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt[0].id
}

# Route tables for private subnets
resource "aws_route_table" "private_rt" {
  count = local.private_cluster ? length(var.availability_zones) : 0

  vpc_id = aws_vpc.cluster_vpc[0].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateways[count.index].id
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-private-rt-${count.index + 1}"
  })
}

# Route table associations for private subnets
resource "aws_route_table_association" "private_rta" {
  count = local.private_cluster ? length(var.availability_zones) : 0

  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}

