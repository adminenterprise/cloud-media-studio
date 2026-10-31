# ==============================================================================
# APPLICATION LOAD BALANCER (ALB) — TUẦN 4: TẦNG CÂN BẰNG TẢI & GẮN WAF
# Phân mảng: Thành viên 1 (Mạng & IaC)
# Phục vụ:
# - Gắn AWS WAFv2 bảo vệ ứng dụng trước SQLi, XSS, DDOS Rate Limit
# - Cung cấp DNS Endpoint công khai và Target Group cho Member 2 (ECS Fargate/EC2)
# - Thiết lập Default Action Fixed-Response 200 OK để Member 1 kiểm thử WAF độc lập
# - EC2 ASG sử dụng target group kiểu instance; ECS Fargate dùng target group kiểu ip
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. APPLICATION LOAD BALANCER (Public Facing)
# ------------------------------------------------------------------------------
locals {
  # Keep the old combined switch working for existing tfvars files.
  enable_alb_effective = var.enable_alb || var.enable_waf || var.enable_alb_and_waf
  enable_waf_effective = var.enable_waf || var.enable_alb_and_waf
}

resource "aws_lb" "main" {
  count              = local.enable_alb_effective ? 1 : 0
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
  count       = local.enable_alb_effective ? 1 : 0
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

# EC2 Auto Scaling Groups register EC2 instance IDs; Fargate uses IP targets.
resource "aws_lb_target_group" "app_ec2" {
  count       = local.enable_alb_effective ? 1 : 0
  name        = "${var.project_name}-ec2"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

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
    Name        = "${var.project_name}-tg-ec2"
    Tier        = "Private-App"
    Role        = "TargetGroup-EC2-ASG"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# 3. HTTP LISTENER (PORT 80)
# ------------------------------------------------------------------------------
# Chế độ Standalone độc lập:
# Trả về Fixed-Response 200 OK giúp Member 1 test và demo kịch bản WAF SQLi/Rate Limiting
# ngay lập tức mà không cần chờ Member 2 hoàn thành code container hay ECS service.
# Chuyển tiếp đến EC2 target group để Member 2 kiểm thử ứng dụng qua ALB.
resource "aws_lb_listener" "http" {
  count             = local.enable_alb_effective ? 1 : 0
  load_balancer_arn = aws_lb.main[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_ec2[0].arn
  }

  tags = {
    Name        = "${var.project_name}-alb-listener-http"
    Environment = var.environment
  }
}

