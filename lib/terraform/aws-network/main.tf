locals {
  subnets = [for subnet in var.aws_network_subnets : merge({
    public = false
  }, subnet)]
}



module "label" {
  source = "../aws-label"

  name = var.name
  team = var.team
  tags = var.tags
}

resource "aws_vpc" "this" {
  cidr_block           = var.aws_network_cidrs.ipv4
  instance_tenancy     = var.aws_network_tenancy
  enable_dns_support   = var.aws_network_enable_dns_support
  enable_dns_hostnames = var.aws_network_enable_dns_hostnames
  tags                 = module.label.tags
}



resource "aws_subnet" "private" {
  for_each = {
    for v in local.subnets : v.ipv4_cidr_block => v
    if v.public == false
  }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.ipv4_cidr_block
  availability_zone = each.value.zone

  tags = merge(module.label.tags, {
    "Name" : "${module.label.id}-private-${each.key}",
    "Subnet-Type" : "private",
    "id" : "${module.label.id}-private-${each.key}",
    "kubernetes.io/role/internal-elb" : 1, # https://stackoverflow.com/questions/62468996/eks-could-not-find-any-suitable-subnets-for-creating-the-elb
  })

}

resource "aws_subnet" "public" {
  for_each = {
    for v in local.subnets : v.ipv4_cidr_block => v
    if v.public == true
  }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.ipv4_cidr_block
  availability_zone       = each.value.zone
  map_public_ip_on_launch = true
  tags = merge(module.label.tags, {
    "Name" : "${module.label.id}-public-${each.key}",
    "Subnet-Type" : "public",
    "id" : "${module.label.id}-public-${each.key}",
    "kubernetes.io/role/elb" : 1
  })
}


resource "aws_route_table" "main_rtb" {
  vpc_id = aws_vpc.this.id
  tags   = module.label.tags
}

resource "aws_route_table" "private_subnet_rtb" {
  for_each = { for subnet in local.subnets : subnet.ipv4_cidr_block => subnet if subnet.public == false }
  vpc_id   = aws_vpc.this.id
  tags     = merge(module.label.tags, { Name = "${module.label.id}-rt-${each.key}" })
}


resource "aws_route_table_association" "private_subnet_rta" {
  for_each = { for subnet in local.subnets : subnet.ipv4_cidr_block => subnet if subnet.public == false }

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private_subnet_rtb[each.key].id
}


resource "aws_internet_gateway" "this" {
  count  = length([for subnet in local.subnets : subnet if subnet.public == true]) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags   = merge(module.label.tags, { Name = "${module.label.id}-igw" })
}

resource "aws_route_table" "public_subnet_rtb" {
  for_each = { for subnet in local.subnets : subnet.ipv4_cidr_block => subnet if subnet.public == true }
  vpc_id   = aws_vpc.this.id
  tags     = merge(module.label.tags, { Name = "${module.label.id}-rt-${each.key}" })
}

resource "aws_route" "public_internet_gateway" {
  for_each               = { for subnet in local.subnets : subnet.ipv4_cidr_block => subnet if subnet.public == true }
  route_table_id         = aws_route_table.public_subnet_rtb[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}


resource "aws_route_table_association" "public_subnet_rta" {
  for_each = { for subnet in local.subnets : subnet.ipv4_cidr_block => subnet if subnet.public == true }

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public_subnet_rtb[each.key].id
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.this.id
  tags   = merge(module.label.tags, { Name = "default for ${module.label.id}" })
}


