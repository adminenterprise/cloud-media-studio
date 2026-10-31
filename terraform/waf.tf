# ==============================================================================
# AWS WAFV2 WEB ACL — TUẦN 4: BẢO MẬT ỨNG DỤNG & GIÁM SÁT TẬP TRUNG
# Phân mảng: Thành viên 1 (Mạng & IaC)
# Phục vụ:
# - Bảo vệ Application Load Balancer (ALB) trước các cuộc tấn công web phổ biến
# - Bộ luật 1: AWSManagedRulesCommonRuleSet (Chặn XSS, Generic Exploits)
# - Bộ luật 2: AWSManagedRulesSQLiRuleSet (Chặn SQL Injection — Trọng tâm Demo Màn 2)
# - Bộ luật 3: Custom Rate-based statement (Chặn tấn công DoS/Brute Force > 100 req/5m)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. AWS WAFV2 WEB ACL (REGIONAL SCOPE GẮN VÀO ALB)
# ------------------------------------------------------------------------------
resource "aws_wafv2_web_acl" "main" {
  count       = local.enable_waf_effective ? 1 : 0
  name        = "${var.project_name}-waf-web-acl"
  description = "AWS WAFv2 Web ACL bao ve ALB truoc SQL Injection, XSS va Rate Limiting"
  scope       = "REGIONAL"

  # Mặc định: Cho phép các request thông thường đi qua
  default_action {
    allow {}
  }

  # ----------------------------------------------------------------------------
  # RULE 1: AWS MANAGED RULES - COMMON RULE SET (CRS)
  # Chặn XSS, Directory Traversal, RFI, LFI, HTTP desync
  # ----------------------------------------------------------------------------
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-waf-common-rules"
      sampled_requests_enabled   = true
    }
  }

  # ----------------------------------------------------------------------------
  # RULE 2: AWS MANAGED RULES - SQL INJECTION RULE SET
  # Chặn các payload SQLi (Ví dụ: ' OR 1=1 --, UNION SELECT)
  # Phục vụ: Trực tiếp kịch bản Demo Màn 2 (WAF Defense - HTTP 403 Forbidden)
  # ----------------------------------------------------------------------------
  rule {
    name     = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-waf-sqli-rules"
      sampled_requests_enabled   = true
    }
  }

  # ----------------------------------------------------------------------------
  # RULE 3: CUSTOM RATE LIMITING RULE
  # Giới hạn tối đa 100 requests trong chu kỳ 5 phút từ mỗi địa chỉ IP
  # Chặn đứng HTTP Flood / Brute-force requests và trả về HTTP 403
  # ----------------------------------------------------------------------------
  rule {
    name     = "Custom-RateLimit-100req-5min"
    priority = 30

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-waf-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  # ----------------------------------------------------------------------------
  # VISIBILITY CONFIG CHO TOÀN BỘ WEB ACL
  # Cung cấp dữ liệu theo dõi cho CloudWatch Metrics & Dashboard của Member 3
  # ----------------------------------------------------------------------------
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf-web-acl"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "${var.project_name}-waf-web-acl"
    Tier        = "Security-Edge"
    Role        = "WAFv2"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# 2. LIÊN KẾT WAF WEB ACL VỚI APPLICATION LOAD BALANCER
# ------------------------------------------------------------------------------
resource "aws_wafv2_web_acl_association" "alb" {
  count        = local.enable_waf_effective ? 1 : 0
  resource_arn = aws_lb.main[0].arn
  web_acl_arn  = aws_wafv2_web_acl.main[0].arn
}

