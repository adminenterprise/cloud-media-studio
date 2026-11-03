# ==============================================================================
# AMAZON ROUTE 53 (DNS) — TUẦN 3: PHÂN GIẢI TÊN MIỀN VÀ ĐIỀU HƯỚNG MẠNG
# ==============================================================================
# - Quản trị DNS Public Hosted Zone
# - Thiết lập bản ghi Alias (A và AAAA) trỏ thẳng về Amazon CloudFront
# - FinOps: Tự động bật/tắt bằng biến enable_route53 để tiết kiệm $0.50/tháng nếu nhóm chưa có domain

# ------------------------------------------------------------------------------
# 1. PUBLIC HOSTED ZONE
# ------------------------------------------------------------------------------
resource "aws_route53_zone" "primary" {
  count = var.enable_route53 && var.domain_name != "" ? 1 : 0

  name    = var.domain_name
  comment = "Hosted Zone cho Cloud Media Studio"

  tags = {
    Name       = "${var.project_name}-dns-zone"
    Week       = "Week-3"
    Tier       = "Edge-DNS"
    CostCenter = "Member1-Network-IaC"
  }
}

# ------------------------------------------------------------------------------
# 2. BẢN GHI ALIAS RECORD (IPV4 - TYPE A) TRỎ VỀ CLOUDFRONT
# ------------------------------------------------------------------------------
resource "aws_route53_record" "apex_ipv4" {
  count = var.enable_route53 && var.domain_name != "" ? 1 : 0

  zone_id = aws_route53_zone.primary[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}

# ------------------------------------------------------------------------------
# 3. BẢN GHI ALIAS RECORD (IPV6 - TYPE AAAA) TRỎ VỀ CLOUDFRONT
# ------------------------------------------------------------------------------
resource "aws_route53_record" "apex_ipv6" {
  count = var.enable_route53 && var.domain_name != "" ? 1 : 0

  zone_id = aws_route53_zone.primary[0].zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}
