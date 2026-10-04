# ==============================================================================
# OUTPUTS — BÀN GIAO THÔNG SỐ HẠ TẦNG CHO THÀNH VIÊN TRONG NHÓM
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. CORE VPC
# ------------------------------------------------------------------------------
output "vpc_id" {
  description = "Production VPC ID (Dùng chung cho cả 4 thành viên)"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block của Production VPC"
  value       = aws_vpc.main.cidr_block
}

# ------------------------------------------------------------------------------
# 2. EDGE TIER (Dùng cho Member 1 & Member 2: ALB, CloudFront, WAF)
# ------------------------------------------------------------------------------
output "public_subnet_ids" {
  description = "Danh sách Public Subnet IDs (Gắn Application Load Balancer)"
  value       = aws_subnet.public[*].id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "Danh sách NAT Gateway IDs đang kích hoạt"
  value       = aws_nat_gateway.main[*].id
}

# ------------------------------------------------------------------------------
# 3. COMPUTE TIER (BÀN GIAO CHO THÀNH VIÊN 2: EC2 ASG, ECS FARGATE, EFS)
# ------------------------------------------------------------------------------
output "private_app_subnet_ids" {
  description = "Danh sách Private App Subnet IDs (Bàn giao cho Member 2 triển khai EC2/ECS/EFS)"
  value       = aws_subnet.private_app[*].id
}

# ------------------------------------------------------------------------------
# 4. DATABASE TIER (BÀN GIAO CHO THÀNH VIÊN 3: RDS MYSQL / AURORA, DYNAMODB)
# ------------------------------------------------------------------------------
output "private_db_subnet_ids" {
  description = "Danh sách Private DB Subnet IDs cách ly (Bàn giao cho Member 3 triển khai RDS Multi-AZ)"
  value       = aws_subnet.private_db[*].id
}

output "rds_db_subnet_group_name" {
  description = "Tên RDS DB Subnet Group đã tạo sẵn (Member 3 chỉ việc tham chiếu vào mã nguồn RDS)"
  value       = aws_db_subnet_group.rds_subnet_group.name
}

# ------------------------------------------------------------------------------
# 5. ROUTE TABLE IDS
# ------------------------------------------------------------------------------
output "public_route_table_id" {
  description = "Route Table ID cho Public Subnets"
  value       = aws_route_table.public.id
}

output "private_app_route_table_ids" {
  description = "Danh sách Route Table IDs cho Private App Subnets"
  value       = aws_route_table.private_app[*].id
}

output "private_db_route_table_id" {
  description = "Route Table ID cho Private DB Subnets"
  value       = aws_route_table.private_db.id
}
