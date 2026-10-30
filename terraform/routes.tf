# ==============================================================================
# 1. PUBLIC ROUTING (Direct Internet Access qua IGW)
# ==============================================================================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-public-rt"
    Tier = "Public"
  }
}

# Keep public routes as standalone aws_route resources. The peering route is
# declared in vpc_peering.tf; do not mix it with inline route blocks above.
resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ==============================================================================
# 2. PRIVATE APPLICATION ROUTING (Egress qua NAT Gateway)
# ==============================================================================
resource "aws_route_table" "private_app" {
  count  = var.single_nat_gateway ? 1 : length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-private-app-rt-${count.index + 1}"
    Tier = "Private-App"
  }
}

resource "aws_route" "private_app_nat" {
  count                  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0
  route_table_id         = aws_route_table.private_app[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}

resource "aws_route_table_association" "private_app" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = var.single_nat_gateway ? aws_route_table.private_app[0].id : aws_route_table.private_app[count.index].id
}

# ==============================================================================
# 3. PRIVATE DATABASE ROUTING (Cách ly 100% - Không định tuyến Internet)
# Tuân thủ nghiêm ngặt chuẩn an ninh Enterprise DevSecOps
# ==============================================================================
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-private-db-rt"
    Tier = "Private-DB-Isolated"
  }
}

resource "aws_route_table_association" "private_db" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_db.id
}
