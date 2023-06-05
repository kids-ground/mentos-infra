resource "aws_vpc" "vpc" {
  cidr_block = var.cidr
  tags = merge(
    {
      Name = format("%s-vpc", var.name)
    },
    var.tags
  )
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    {
      Name = format("%s-igw", var.name)
    },
    var.tags
  )
}


# public subnets
resource "aws_subnet" "public_subnets" {
  for_each = var.public_subnets
  vpc_id = aws_vpc.vpc.id
  cidr_block = each.value["cidr"]
  availability_zone = each.value["zone"]

  tags = merge(
    {
      Name = format(
        "%s-public-subnet-%s",
        var.name,
        each.key
      )
    },
    var.tags
  )
}


# private subnets
resource "aws_subnet" "private_subnets" {
  for_each = var.private_subnets
  vpc_id = aws_vpc.vpc.id
  cidr_block = each.value["cidr"]
  availability_zone = each.value["zone"]

  tags = merge(
    {
      Name = format(
        "%s-private-subnet-%s",
        var.name,
        each.key
      )
    },
    var.tags
  )
}


# public subnet - route table
resource "aws_route_table" "public_route_table" {
  for_each = var.public_subnets
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    {
      Name = format(
        "%s-public-route-table-%s",
        var.name,
        each.key
      )
    },
    var.tags
  )
}

resource "aws_route_table_association" "public_route" {
  for_each = var.public_subnets
  subnet_id = aws_subnet.public_subnets[each.key].id
  route_table_id = aws_route_table.public_route_table[each.key].id
}


# private subnet - route table
resource "aws_route_table" "private_route_table" {
  for_each = var.private_subnets
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    {
      Name = format(
        "%s-private-route-table-%s",
        var.name,
        each.key
      )
    },
    var.tags
  )
}

resource "aws_route_table_association" "private_route" {
  for_each = var.private_subnets
  subnet_id = aws_subnet.private_subnets[each.key].id
  route_table_id = aws_route_table.private_route_table[each.key].id 
}