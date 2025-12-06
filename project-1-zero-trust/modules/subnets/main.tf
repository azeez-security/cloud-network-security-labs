# Public subnets + route table (Internet-facing for LB / bastion)
resource "aws_subnet" "public" {
  for_each = {
    for idx, cidr in var.public_subnet_cidrs :
    idx => {
      cidr = cidr
      az   = var.azs[idx]
    }
  }

  vpc_id                  = var.vpc_id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-public-${each.value.az}"
      Tier = "public"
    }
  )
}

resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-public-rt"
    }
  )
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Private app subnets (no internet route by default)
resource "aws_subnet" "private_app" {
  for_each = {
    for idx, cidr in var.private_app_subnet_cidrs :
    idx => {
      cidr = cidr
      az   = var.azs[idx]
    }
  }

  vpc_id            = var.vpc_id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-app-${each.value.az}"
      Tier = "app"
    }
  )
}

# Private DB subnets
resource "aws_subnet" "private_db" {
  for_each = {
    for idx, cidr in var.private_db_subnet_cidrs :
    idx => {
      cidr = cidr
      az   = var.azs[idx]
    }
  }

  vpc_id            = var.vpc_id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-db-${each.value.az}"
      Tier = "db"
    }
  )
}

# Logging / security tools subnets
resource "aws_subnet" "logging" {
  for_each = {
    for idx, cidr in var.logging_subnet_cidrs :
    idx => {
      cidr = cidr
      az   = var.azs[idx]
    }
  }

  vpc_id            = var.vpc_id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-logging-${each.value.az}"
      Tier = "logging"
    }
  )
}
