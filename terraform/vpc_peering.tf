# ==============================================================================
# TUẦN 5: KIẾN TRÚC MỞ RỘNG MULTI-VPC & VPC PEERING CONNECTION
# Phân mảng: Thành viên 1 (Mạng & IaC — Nhóm trưởng)
# Phục vụ:
# - Khởi tạo VPC thứ 2: Management / DevSecOps VPC (Dải mạng 10.1.0.0/16)
# - Thiết lập kết nối VPC Peering giữa Production VPC (10.0.0.0/16) và Management VPC (10.1.0.0/16)
# - Cấu hình bảng định tuyến Route Tables 2 chiều (Bidirectional Inter-VPC Routing)
# - Đặt Security Group an toàn cho Bastion Host / CI-CD Runners
# - FinOps: 100% MIỄN PHÍ ($0.00 duy trì theo giờ)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. MANAGEMENT / DEVSECOPS VPC (VPC THỨ 2)
# ------------------------------------------------------------------------------
resource "aws_vpc" "management" {
  cidr_block           = var.management_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-management-vpc"
    Tier        = "Management-DevSecOps"
    Environment = var.environment
    Role        = "Ops-Bastion-CI-CD"
  }
}

# ------------------------------------------------------------------------------
# 2. MANAGEMENT SUBNETS (Multi-AZ)
# ------------------------------------------------------------------------------
resource "aws_subnet" "management" {
  count                   = length(var.management_subnet_cidrs)
  vpc_id                  = aws_vpc.management.id
  cidr_block              = var.management_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true # Public IP phục vụ SSH Bastion / CI-CD Runner

  tags = {
    Name        = "${var.project_name}-mgmt-subnet-${var.availability_zones[count.index]}"
    Tier        = "Management-Public"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# 3. INTERNET GATEWAY CHO MANAGEMENT VPC
# ------------------------------------------------------------------------------
resource "aws_internet_gateway" "management" {
  vpc_id = aws_vpc.management.id

  tags = {
    Name        = "${var.project_name}-mgmt-igw"
    Tier        = "Management-Edge"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# 4. ROUTE TABLE CHO MANAGEMENT VPC
# ------------------------------------------------------------------------------
resource "aws_route_table" "management" {
  vpc_id = aws_vpc.management.id

  # Định tuyến ra Internet qua Management IGW
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.management.id
  }

  # Định tuyến sang Production VPC (10.0.0.0/16) thông qua VPC Peering Connection
  route {
    cidr_block                = var.vpc_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.prod_to_mgmt.id
  }

  tags = {
    Name        = "${var.project_name}-mgmt-rt"
    Tier        = "Management-Routing"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "management" {
  count          = length(var.management_subnet_cidrs)
  subnet_id      = aws_subnet.management[count.index].id
  route_table_id = aws_route_table.management.id
}

# ------------------------------------------------------------------------------
# 5. VPC PEERING CONNECTION (GIỮA PROD VPC VÀ MGMT VPC)
# ------------------------------------------------------------------------------
resource "aws_vpc_peering_connection" "prod_to_mgmt" {
  peer_vpc_id = aws_vpc.management.id
  vpc_id      = aws_vpc.main.id
  auto_accept = true # Cùng một tài khoản AWS & Region nên auto accept

  tags = {
    Name        = "${var.project_name}-prod-to-mgmt-peering"
    Side        = "Requester:Prod-Accepter:Mgmt"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# 6. CẬP NHẬT ĐỊNH TUYẾN TỪ PRODUCTION VPC SANG MANAGEMENT VPC (10.1.0.0/16)
# ------------------------------------------------------------------------------
# Định tuyến từ Public Route Table của Production VPC sang Management VPC
resource "aws_route" "prod_public_to_mgmt" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = var.management_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.prod_to_mgmt.id
}

# Định tuyến từ Private App Route Table của Production VPC sang Management VPC
resource "aws_route" "prod_private_app_to_mgmt" {
  count                     = length(aws_route_table.private_app)
  route_table_id            = aws_route_table.private_app[count.index].id
  destination_cidr_block    = var.management_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.prod_to_mgmt.id
}

# Định tuyến từ Private DB Route Table của Production VPC sang Management VPC (DBA quản trị nội bộ)
resource "aws_route" "prod_private_db_to_mgmt" {
  route_table_id            = aws_route_table.private_db.id
  destination_cidr_block    = var.management_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.prod_to_mgmt.id
}

# ------------------------------------------------------------------------------
# 7. SECURITY GROUP CHO BASTION HOST / MANAGEMENT TOOLING
# ------------------------------------------------------------------------------
resource "aws_security_group" "management_bastion" {
  name        = "${var.project_name}-mgmt-bastion-sg"
  description = "Kiem soat truy cap SSH Admin vao Management VPC va Egress sang Production VPC"
  vpc_id      = aws_vpc.management.id

  # Inbound: SSH từ IP Admin
  ingress {
    description = "SSH tu dia chi IP quan tri vien"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }

  # Outbound: Sang Production VPC (cho phép SSH hoặc quản trị DB/App nội bộ)
  egress {
    description = "Truy cap noi bo sang Production VPC qua VPC Peering"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  # Outbound: HTTPS ra ngoài để tải bản vá / packages
  egress {
    description = "HTTPS ra ngoai Internet de cap nhat OS va packages"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-mgmt-bastion-sg"
    Tier        = "Management-Security"
    Environment = var.environment
  }
}
