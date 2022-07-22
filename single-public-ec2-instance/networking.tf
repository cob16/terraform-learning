provider "aws" {
  region = "eu-west-1"
}

data "aws_availability_zones" "az" {}

resource "aws_vpc" "main" {
  cidr_block                       = "10.0.0.0/16"
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true

  tags = {
    Name : "main"
  }
}

resource "aws_subnet" "public-1" {
  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.az.names[0]

  cidr_block                                  = cidrsubnet(aws_vpc.main.cidr_block, 8, 1) #makes a /24 = 254 ips
  map_public_ip_on_launch                     = true
  enable_resource_name_dns_a_record_on_launch = true

  ipv6_cidr_block                                = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 1)
  assign_ipv6_address_on_creation                = true
  enable_resource_name_dns_aaaa_record_on_launch = true
  private_dns_hostname_type_on_launch            = "resource-name"
  enable_dns64                                   = true

  tags = {
    Name = "public-1"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

resource "aws_default_route_table" "main" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  route {
    gateway_id = aws_internet_gateway.main.id
    cidr_block = "0.0.0.0/0"
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.main.id
  }
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

locals {
  local_ip = "${chomp(data.http.myip.body)}/32"
}

resource "aws_security_group" "public" {
  vpc_id      = aws_vpc.main.id
  name_prefix = "public"

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = [local.local_ip]
    description = "allow ping"
  }

#  ingress {
#    from_port        = 128
#    to_port          = 0
#    protocol         = "ICMPv6"
#    ipv6_cidr_blocks = ["::/0"]
#    description      = "allow everyone to make a ipv6 ping"
#  }

  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = [local.local_ip]
    description = "allow http"
  }

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = [local.local_ip]
    description = "allow ssh"
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow apt to fetch packages"
  }
}
