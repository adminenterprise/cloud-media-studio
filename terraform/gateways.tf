# ==============================================================================
# 1. INTERNET GATEWAY (Cho phép các tài nguyên Public truy cập Internet)
# ==============================================================================
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
    Tier = "Edge"
  }
}

# ==============================================================================
# 2. ELASTIC IP CHO NAT GATEWAY
# ==============================================================================
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-${var.availability_zones[count.index]}"
    Tier = "Edge"
  }

  depends_on = [aws_internet_gateway.main]
}

# ==============================================================================
# 3. NAT GATEWAY (Cho phép Private Subnet gọi ra Internet để tải bản vá/packages)
# Thiết kế FinOps: Mặc định 1 NAT Gateway duy nhất tại Public Subnet AZ-a để tối ưu ngân sách
# ==============================================================================
resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.project_name}-nat-gateway-${var.availability_zones[count.index]}"
    Tier = "Edge"
  }

  depends_on = [aws_internet_gateway.main]
}
