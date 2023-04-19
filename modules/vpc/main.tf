locals {
  vpc_id             = aws_vpc.this[0].id
  public_subnet_ids  = aws_subnet.public.*.id
  private_subnet_ids = aws_subnet.private.*.id
}

resource "aws_vpc" "this" {
  count = var.create_vpc ? 1 : 0

  cidr_block       = var.cidr_block
  instance_tenancy = var.instance_tenancy
  tags = merge(
    {
      "Name" = format("%s", var.name)
    },
    var.tags,
  )
}

resource "aws_subnet" "public" {
  count = var.create_vpc && length(var.availability_zone_public_susbnets) == length(var.cidr_block_public_subnets) ? length(var.cidr_block_public_subnets) : 0

  vpc_id            = local.vpc_id
  cidr_block        = element(var.cidr_block_public_subnets, count.index)
  availability_zone = element(var.availability_zone_public_susbnets, count.index)
  tags = merge(
    {
      "Name" = format(
        "%s-%s-%s",
        var.name,
        "subnet",
        element(var.cidr_block_public_subnets, count.index),
      )
    },
    var.tags,
  )
}

resource "aws_subnet" "private" {
  count = var.create_vpc && length(var.availability_zone_private_susbnets) == length(var.cidr_block_private_subnets) ? length(var.cidr_block_private_subnets) : 0

  vpc_id            = local.vpc_id
  cidr_block        = element(var.cidr_block_private_subnets, count.index)
  availability_zone = element(var.availability_zone_private_susbnets, count.index)
  tags = merge(
    {
      "Name" = format(
        "%s-%s-%s",
        var.name,
        "subnet",
        element(var.cidr_block_private_subnets, count.index),
      )
    },
    var.tags,
  )
}

resource "aws_internet_gateway" "this" {
  count = var.create_igw && length(var.cidr_block_public_subnets) > 0 ? 1 : 0

  vpc_id = local.vpc_id
  tags = merge(
    {
      "Name" = format(
        "%s-%s",
        var.name,
        "igw",
      )
    },
    var.tags,
  )
}

locals {
  eip_id = aws_eip.nat.*.id
}

resource "aws_eip" "nat" {
  count = var.create_vpc && var.create_nat ? 1 : 0

  vpc = true

  tags = merge(
    {
      "Name" = format(
        "%s-%s",
        var.name,
        "eip",
      )
    },
    var.tags,
  )
}

resource "aws_nat_gateway" "this" {
  count = var.create_vpc && var.create_nat ? 1 : 0

  allocation_id = local.eip_id[0]
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    {
      "Name" = format(
        "%s-%s",
        var.name,
        "nat",
      )
    },
    var.tags,
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  count = var.create_vpc && length(var.cidr_block_public_subnets) > 0 ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(
    {
      "Name" = format(
        "%s-%s",
        var.name,
        "public-route",
      )
    },
    var.tags,
  )
}

resource "aws_route" "public_internet_gateway" {
  count = var.create_vpc && var.create_igw && length(var.cidr_block_public_subnets) > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "public" {
  count = var.create_vpc && length(var.cidr_block_public_subnets) > 0 ? length(var.cidr_block_public_subnets) : 0

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table" "private" {
  count = var.create_vpc && length(var.cidr_block_private_subnets) > 0 ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(
    {
      "Name" = format(
        "%s-%s",
        var.name,
        "private-route",
      )
    },
    var.tags,
  )
}

resource "aws_route" "private_nat_gateway" {
  count = var.create_vpc && var.create_nat && length(var.cidr_block_private_subnets) > 0 ? 1 : 0

  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.this[0].id
}

resource "aws_route_table_association" "private" {
  count = var.create_vpc && length(var.cidr_block_private_subnets) > 0 ? length(var.cidr_block_private_subnets) : 0

  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private[0].id
}
