# ==============================================================================
# 1. PUBLIC SUBNETS (Edge Tier - Load Balancers, NAT Gateways, Bastion)
# ==============================================================================
resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${var.availability_zones[count.index]}"
    Tier = "Public"
  }
}

# ==============================================================================
# 2. PRIVATE APPLICATION SUBNETS (Compute Tier - EC2 ASG, ECS Fargate, EFS)
# ==============================================================================
resource "aws_subnet" "private_app" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_app_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-private-app-subnet-${var.availability_zones[count.index]}"
    Tier = "Private-App"
    Role = "Compute-ECS-EC2"
  }
}

# ==============================================================================
# 3. PRIVATE DATABASE SUBNETS (Data Tier - RDS Aurora, MySQL - Isolated)
# ==============================================================================
resource "aws_subnet" "private_db" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_db_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-private-db-subnet-${var.availability_zones[count.index]}"
    Tier = "Private-DB"
    Role = "Database-Storage-Isolated"
  }
}

# RDS DB Subnet Group (Tiện ích bàn giao sẵn cho Member 3 triển khai RDS)
resource "aws_db_subnet_group" "rds_subnet_group" {
  name        = "${var.project_name}-db-subnet-group"
  description = "Database subnet group for RDS Multi-AZ instances in isolated subnets"
  subnet_ids  = aws_subnet.private_db[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group"
    Tier = "Private-DB"
  }
}
