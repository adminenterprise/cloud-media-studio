# ==============================================================================
# APPLICATION LOAD BALANCER (ALB) — TUẦN 4: TẦNG CÂN BẰNG TẢI & GẮN WAF
# Phân mảng: Thành viên 1 (Mạng & IaC)
# Phục vụ:
# - Gắn AWS WAFv2 bảo vệ ứng dụng trước SQLi, XSS, DDOS Rate Limit
# - Cung cấp DNS Endpoint công khai và Target Group cho Member 2 (ECS Fargate/EC2)
# - Thiết lập Default Action Fixed-Response 200 OK để Member 1 kiểm thử WAF độc lập
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. APPLICATION LOAD BALANCER (Public Facing)
# ------------------------------------------------------------------------------
resource "aws_lb" "main" {
  count              = var.enable_alb_and_waf ? 1 : 0
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  # FinOps: Tắt deletion protection trong môi trường đồ án sinh viên để dễ dàng destroy dọn dẹp credit
  enable_deletion_protection = var.enable_alb_deletion_protection

  tags = {
    Name        = "${var.project_name}-alb"
    Tier        = "Public"
    Role        = "Edge-LoadBalancer"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# 2. TARGET GROUP (Chuẩn bị sẵn cho Member 2 - ECS Fargate / EC2 ASG)
# ------------------------------------------------------------------------------
resource "aws_lb_target_group" "app" {
  count       = var.enable_alb_and_waf ? 1 : 0
  name        = "${var.project_name}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # Chuẩn tối ưu cho ECS Fargate Multi-AZ


  health_check {
    enabled             = true
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.project_name}-tg-app"
    Tier        = "Private-App"
    Role        = "TargetGroup-ECS-Fargate"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# 3. HTTP LISTENER (PORT 80)
# ------------------------------------------------------------------------------
# Chế độ Standalone độc lập:
# Trả về Fixed-Response 200 OK giúp Member 1 test và demo kịch bản WAF SQLi/Rate Limiting
# ngay lập tức mà không cần chờ Member 2 hoàn thành code container hay ECS service.
resource "aws_lb_listener" "http" {
  count             = var.enable_alb_and_waf ? 1 : 0
  load_balancer_arn = aws_lb.main[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = "<!DOCTYPE html><html><head><meta charset=\"utf-8\"><title>DevSecOps Platform</title><style>body{background:#0b0f19;color:#f1f5f9;font-family:sans-serif;text-align:center;padding:50px}h1{color:#38bdf8}span{background:#15803d;padding:5px 12px;border-radius:12px;font-size:13px;font-weight:bold;margin:4px;display:inline-block}.b{background:#0369a1}</style></head><body><h1>Enterprise Cloud &amp; DevSecOps Platform</h1><p>Application Load Balancer &amp; AWS WAFv2 Online</p><p><span class=\"b\">ALB: Active</span> <span>WAFv2: Protected</span></p><p style=\"color:#94a3b8;font-size:12px;margin-top:15px\">Tu&#7847;n 4 - M&#7841;ng &amp; IaC (Member 1): Ready for ECS Fargate</p></body></html>"
      status_code  = "200"
    }
  }

  tags = {
    Name        = "${var.project_name}-alb-listener-http"
    Environment = var.environment
  }
}

