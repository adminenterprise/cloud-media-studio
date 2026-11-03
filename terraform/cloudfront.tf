# ==============================================================================
# AMAZON CLOUDFRONT DISTRIBUTION (CDN) — TUẦN 3: TỐI ƯU HÓA TẢI TRANG TOÀN CẦU
# ==============================================================================
# Kiến trúc Edge Tier:
# - Phân phối nội dung tĩnh từ Amazon S3 qua Origin Access Control (OAC) bảo mật cao
# - Dự phòng Origin chuyển tiếp API động (/api/*) về Application Load Balancer (ALB)
# - FinOps: Sử dụng PriceClass_100 để tối ưu hóa chi phí gói tài trợ $200

locals {
  s3_origin_id   = "S3-${var.s3_static_assets_bucket_name}"
  alb_origin_id  = "ALB-Backend"
  s3_domain_name = "${var.s3_static_assets_bucket_name}.s3.${var.aws_region}.amazonaws.com"
}

# ------------------------------------------------------------------------------
# 1. ORIGIN ACCESS CONTROL (OAC) — Chuẩn bảo mật mới nhất của AWS (thay thế OAI cũ)
# ------------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "${var.project_name}-s3-oac"
  description                       = "OAC cho S3 Static Assets Bucket bảo mật truy cập từ CloudFront"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ------------------------------------------------------------------------------
# 2. CLOUDFRONT DISTRIBUTION
# ------------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront CDN cho Cloud Media Studio"
  default_root_object = "index.html"

  # FinOps: PriceClass_100 chỉ dùng các PoP tại Bắc Mỹ, Châu Âu, Singapore, Hong Kong
  # Tiết kiệm chi phí nhất, phù hợp cho đồ án sinh viên
  price_class = "PriceClass_100"

  # Alias (Custom Domain) nếu enable_route53 = true và có domain_name
  aliases = var.enable_route53 && var.domain_name != "" ? [var.domain_name] : []

  # ----------------------------------------------------------------------------
  # ORIGIN 1: S3 STATIC ASSETS (Frontend, Images, CSS, JS) — Từ Member 3
  # ----------------------------------------------------------------------------
  origin {
    domain_name              = local.s3_domain_name
    origin_id                = local.s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  # ----------------------------------------------------------------------------
  # ORIGIN 2: APPLICATION LOAD BALANCER (Backend API) — Chờ Member 2 (Optional)
  # ----------------------------------------------------------------------------
  dynamic "origin" {
    for_each = var.alb_dns_name != "" ? [var.alb_dns_name] : []
    content {
      domain_name = origin.value
      origin_id   = local.alb_origin_id

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "http-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  # ----------------------------------------------------------------------------
  # DEFAULT CACHE BEHAVIOR: TRỎ VỀ S3 (Static Web Content)
  # ----------------------------------------------------------------------------
  default_cache_behavior {
    target_origin_id       = local.s3_origin_id
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # Bộ nhớ đệm tĩnh tối ưu tốc độ tải trang
    min_ttl     = 0
    default_ttl = 86400    # 24 giờ
    max_ttl     = 31536000 # 365 ngày

    forwarded_values {
      query_string = false
      headers      = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]

      cookies {
        forward = "none"
      }
    }
  }

  # ----------------------------------------------------------------------------
  # ORDERED CACHE BEHAVIOR: TRỎ VỀ ALB CHO ĐƯỜNG DẪN /api/* (Nếu có ALB)
  # ----------------------------------------------------------------------------
  dynamic "ordered_cache_behavior" {
    for_each = var.alb_dns_name != "" ? [1] : []
    content {
      path_pattern           = "/api/*"
      target_origin_id       = local.alb_origin_id
      allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods         = ["GET", "HEAD"]
      viewer_protocol_policy = "redirect-to-https"
      compress               = true

      # Dynamic API bypass hoàn toàn cache
      min_ttl     = 0
      default_ttl = 0
      max_ttl     = 0

      forwarded_values {
        query_string = true
        headers      = ["*"]

        cookies {
          forward = "all"
        }
      }
    }
  }

  # ----------------------------------------------------------------------------
  # SPA ROUTING: CUSTOM ERROR RESPONSES (403 & 404 -> /index.html)
  # ----------------------------------------------------------------------------
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  # ----------------------------------------------------------------------------
  # CHỨNG CHỈ BẢO MẬT SSL/TLS
  # ----------------------------------------------------------------------------
  viewer_certificate {
    cloudfront_default_certificate = var.domain_name == "" || !var.enable_route53 ? true : false
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  # ----------------------------------------------------------------------------
  # HẠN CHẾ ĐỊA LÝ (Không chặn khu vực nào)
  # ----------------------------------------------------------------------------
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name       = "${var.project_name}-cloudfront"
    Tier       = "Edge-CDN"
    Week       = "Week-3"
    CostCenter = "Member1-Network-IaC"
  }
}

# ------------------------------------------------------------------------------
# 3. S3 BUCKET POLICY CHO PHÉP CLOUDFRONT OAC TRUY CẬP (Least Privilege)
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "s3_cloudfront_oac_access" {
  statement {
    sid       = "AllowCloudFrontServicePrincipalReadOnly"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.s3_static_assets_bucket_name}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.main.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudfront_s3_access" {
  bucket = var.s3_static_assets_bucket_name
  policy = data.aws_iam_policy_document.s3_cloudfront_oac_access.json
}
