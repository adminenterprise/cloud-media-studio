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

# ------------------------------------------------------------------------------
# 6. SECURITY GROUP IDS (BÀN GIAO CHO CÁC THÀNH VIÊN — TUẦN 2)
# ------------------------------------------------------------------------------
output "alb_security_group_id" {
  description = "Security Group ID cho ALB (Bàn giao cho Member 2 gắn vào Load Balancer)"
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "Security Group ID cho App Servers EC2/ECS (Bàn giao cho Member 2)"
  value       = aws_security_group.app.id
}

output "db_security_group_id" {
  description = "Security Group ID cho RDS MySQL/Aurora (Bàn giao cho Member 3)"
  value       = aws_security_group.db.id
}

output "efs_security_group_id" {
  description = "Security Group ID cho Amazon EFS (Bàn giao cho Member 2 mount storage)"
  value       = aws_security_group.efs.id
}

output "bastion_security_group_id" {
  description = "Security Group ID cho Bastion Host (Admin SSH access)"
  value       = aws_security_group.bastion.id
}

# ------------------------------------------------------------------------------
# 7. CLOUDFRONT CDN (TUẦN 3 — BÀN GIAO CHO MEMBER 4 GẮN WAF & KIỂM THỬ)
# ------------------------------------------------------------------------------
output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID (Dùng để gắn AWS WAF ở Tuần 4)"
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_distribution_arn" {
  description = "CloudFront Distribution ARN"
  value       = aws_cloudfront_distribution.main.arn
}

output "cloudfront_domain_name" {
  description = "Tên miền mặc định của CloudFront (Dùng để truy cập kiểm thử web tĩnh & API)"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront Route 53 Zone ID (Z2FDTNDATAQYW2)"
  value       = aws_cloudfront_distribution.main.hosted_zone_id
}

# ------------------------------------------------------------------------------
# 8. ROUTE 53 DNS (TUẦN 3)
# ------------------------------------------------------------------------------
output "route53_zone_id" {
  description = "Route 53 Public Hosted Zone ID"
  value       = try(aws_route53_zone.primary[0].zone_id, "Route 53 chưa được bật (enable_route53 = false)")
}

output "route53_name_servers" {
  description = "Danh sách Name Servers của Route 53 (cần cấu hình tại Registrar nếu có custom domain)"
  value       = try(aws_route53_zone.primary[0].name_servers, [])
}

# ------------------------------------------------------------------------------
# 9. APPLICATION LOAD BALANCER (TUẦN 4 — BÀN GIAO CHO MEMBER 2)
# ------------------------------------------------------------------------------
output "alb_id" {
  description = "Application Load Balancer ID"
  value       = try(aws_lb.main[0].id, "ALB chưa được bật (enable_alb_and_waf = false)")
}

output "alb_arn" {
  description = "Application Load Balancer ARN (Dùng để gắn WAF hoặc cấu hình CloudWatch)"
  value       = try(aws_lb.main[0].arn, "ALB chưa được bật (enable_alb_and_waf = false)")
}

output "alb_dns_name" {
  description = "DNS công khai của ALB (Dùng để truy cập trực tiếp kiểm thử)"
  value       = try(aws_lb.main[0].dns_name, "ALB chưa được bật (enable_alb_and_waf = false)")
}

output "alb_zone_id" {
  description = "Route 53 Zone ID của ALB (Dùng cho Route 53 Alias record)"
  value       = try(aws_lb.main[0].zone_id, "ALB chưa được bật (enable_alb_and_waf = false)")
}

output "alb_target_group_arn" {
  description = "Target Group ARN (Bàn giao cho Member 2 cắm ECS Fargate / EC2 ASG)"
  value       = try(aws_lb_target_group.app[0].arn, "Target Group chưa được bật (enable_alb_and_waf = false)")
}

output "alb_target_group_name" {
  description = "Target Group Name"
  value       = try(aws_lb_target_group.app[0].name, "Target Group chưa được bật (enable_alb_and_waf = false)")
}

# ------------------------------------------------------------------------------
# 10. AWS WAFV2 WEB ACL (TUẦN 4 — BẢO MẬT & KỊCH BẢN DEMO MÀN 2)
# ------------------------------------------------------------------------------
output "waf_web_acl_id" {
  description = "AWS WAFv2 Web ACL ID"
  value       = try(aws_wafv2_web_acl.main[0].id, "WAF chưa được bật (enable_alb_and_waf = false)")
}

output "waf_web_acl_arn" {
  description = "AWS WAFv2 Web ACL ARN"
  value       = try(aws_wafv2_web_acl.main[0].arn, "WAF chưa được bật (enable_alb_and_waf = false)")
}

output "waf_web_acl_name" {
  description = "Tên Web ACL bảo vệ ALB"
  value       = try(aws_wafv2_web_acl.main[0].name, "WAF chưa được bật (enable_alb_and_waf = false)")
}

output "waf_web_acl_capacity" {
  description = "WCU (Web ACL Capacity Units) đã sử dụng"
  value       = try(aws_wafv2_web_acl.main[0].capacity, 0)
}

# ------------------------------------------------------------------------------
# 11. MULTI-VPC & PEERING (TUẦN 5 — KIẾN TRÚC MỞ RỘNG DOANH NGHIỆP)
# ------------------------------------------------------------------------------
output "management_vpc_id" {
  description = "Management / DevSecOps VPC ID (VPC thứ 2)"
  value       = aws_vpc.management.id
}

output "management_vpc_cidr" {
  description = "CIDR block của Management VPC"
  value       = aws_vpc.management.cidr_block
}

output "management_subnet_ids" {
  description = "Danh sách Management Subnet IDs (Nơi đặt Bastion Host / CI-CD Runners)"
  value       = aws_subnet.management[*].id
}

output "vpc_peering_connection_id" {
  description = "VPC Peering Connection ID giữa Production VPC và Management VPC"
  value       = aws_vpc_peering_connection.prod_to_mgmt.id
}

output "vpc_peering_accept_status" {
  description = "Trạng thái kết nối VPC Peering (active)"
  value       = aws_vpc_peering_connection.prod_to_mgmt.accept_status
}

output "management_bastion_security_group_id" {
  description = "Security Group ID của Bastion Host trong Management VPC"
  value       = aws_security_group.management_bastion.id
}


