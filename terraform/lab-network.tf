resource "aws_vpc" "vpc" {
  cidr_block = "192.168.0.0/22"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
}

data "aws_availability_zones" "azs" {
  state = "available"
}

resource "aws_subnet" "public_subnet_az0" {
  availability_zone = data.aws_availability_zones.azs.names[0]
  cidr_block        = "192.168.0.0/24"
  vpc_id            = aws_vpc.vpc.id
}

resource "aws_subnet" "private_subnet_az0" {
  availability_zone = data.aws_availability_zones.azs.names[0]
  cidr_block        = "192.168.1.0/24"
  vpc_id            = aws_vpc.vpc.id
}

resource "aws_subnet" "private_subnet_az1" {
  availability_zone = data.aws_availability_zones.azs.names[1]
  cidr_block        = "192.168.2.0/24"
  vpc_id            = aws_vpc.vpc.id
}

resource "aws_subnet" "private_subnet_az2" {
  availability_zone = data.aws_availability_zones.azs.names[2]
  cidr_block        = "192.168.3.0/24"
  vpc_id            = aws_vpc.vpc.id
}

# Internet GW
resource "aws_internet_gateway" "edge-gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

# route tables for public transit subnet
resource "aws_route_table" "msk_lab" {
  vpc_id = aws_vpc.main.id
}

# route associations public
resource "aws_route_table_association" "public_subnet_az0_default_route_asc" {
  subnet_id      = aws_subnet.public_subnet_az0.id
  route_table_id = aws_route_table.public_subnet_az0_default_route.id
}   

resource "aws_route" "default_route" {
    route_table_id = aws_route_table.msk_lab
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.edge-gw.id

    tags = {
        name = "default_route"
        subnet = "public_subnet_az0"
  }

}

# resource "aws_route" "private_subnet_transit_route" {
#   vpc_id = aws_vpc.main.id
#   route {
#     cidr_block = aws_subnet.public_subnet_az0.cidr_block
#     gateway_id = aws_internet_gateway.edge-gw.id
#   }
}

resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.vpc.id
}