# ==============================================================================
# AMAZON CLOUDWATCH — TUẦN 4: HỆ THỐNG GIÁM SÁT & CẢNH BÁO TẬP TRUNG
# ==============================================================================
# Phân mảng: Thành viên 3 (Dữ liệu & FinOps — Phạm Thế Hùng)
# Mục tiêu:
# 1. CloudWatch Log Groups với Retention Period = 7 ngày (FinOps guardrail tránh phình chi phí)
# 2. SNS Topic phát cảnh báo đa kênh (Email) tới toàn bộ thành viên nhóm
# 3. CloudWatch Metric Alarms giám sát ngưỡng quá tải CPU > 70% (RDS, Container) và hạn mức ngân sách
# 4. CloudWatch Dashboard tổng quan quan sát toàn diện hạ tầng (RDS, ECS, WAF, FinOps Billing)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. SNS TOPIC & EMAIL SUBSCRIPTIONS (HỆ THỐNG CẢNH BÁO TỨC THÌ)
# ------------------------------------------------------------------------------
resource "aws_sns_topic" "alerts" {
  name              = "${var.project_name}-alerts-topic"
  display_name      = "Enterprise Cloud DevSecOps System Alerts"
  kms_master_key_id = "alias/aws/sns" # Mã hóa SSE at-rest bảo vệ dữ liệu thông báo

  tags = {
    Name       = "${var.project_name}-alerts-topic"
    Tier       = "Observability"
    Week       = "Week-4"
    CostCenter = "Member3-Data-FinOps"
  }
}

# Tự động đăng ký email nhận thông báo cảnh báo từ biến notification_emails
resource "aws_sns_topic_subscription" "email_alerts" {
  for_each  = toset(var.notification_emails)
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

# ------------------------------------------------------------------------------
# 2. CLOUDWATCH LOG GROUPS (FINOPS GUARDRAILS: RETENTION = 7 NGÀY)
# ------------------------------------------------------------------------------
# Log Group cho Ứng dụng Backend / Container (Member 2)
resource "aws_cloudwatch_log_group" "app_backend" {
  name              = "/ecs/${var.project_name}-backend-app"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = {
    Name       = "${var.project_name}-backend-log-group"
    Tier       = "Compute"
    Week       = "Week-4"
    FinOpsRule = "7-Days-Retention-Expiration"
  }
}

# Log Group cho RDS MySQL Error Log & Slow Query Log
resource "aws_cloudwatch_log_group" "rds_error" {
  name              = "/aws/rds/instance/${var.project_name}-mysql-primary/error"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = {
    Name       = "${var.project_name}-rds-error-log-group"
    Tier       = "Database"
    Week       = "Week-4"
    FinOpsRule = "7-Days-Retention-Expiration"
  }
}

resource "aws_cloudwatch_log_group" "rds_slowquery" {
  name              = "/aws/rds/instance/${var.project_name}-mysql-primary/slowquery"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = {
    Name       = "${var.project_name}-rds-slowquery-log-group"
    Tier       = "Database"
    Week       = "Week-4"
    FinOpsRule = "7-Days-Retention-Expiration"
  }
}

# Log Group nhận vết kiểm toán từ AWS CloudTrail
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.project_name}-audit-logs"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = {
    Name       = "${var.project_name}-cloudtrail-log-group"
    Tier       = "Governance-Security"
    Week       = "Week-4"
    FinOpsRule = "7-Days-Retention-Expiration"
  }
}

# ------------------------------------------------------------------------------
# 3. CLOUDWATCH METRIC ALARMS (CẢNH BÁO QUÁ TẢI CPU > 70% & SỰ CỐ DỮ LIỆU)
# ------------------------------------------------------------------------------

# Alarm 1: RDS MySQL Quá tải CPU >= 70% (2 chu kỳ liên tiếp 5 phút)
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.project_name}-rds-cpu-high-alert"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300 # 5 phút
  statistic           = "Average"
  threshold           = var.cpu_utilization_alarm_threshold # 70%
  alarm_description   = "Canh bao khac phuc: RDS MySQL CPU vuot nguong 70% trong 10 phut lien tiep. Yeu cau toi uu truy van hoac scale up instance."

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mysql_primary.identifier
  }

  alarm_actions             = [aws_sns_topic.alerts.arn]
  ok_actions                = [aws_sns_topic.alerts.arn]
  insufficient_data_actions = []

  tags = {
    Name       = "${var.project_name}-rds-cpu-alarm"
    Tier       = "Database"
    Week       = "Week-4"
    MetricType = "CPUUtilization"
  }
}

# Alarm 2: RDS MySQL Dung lượng ổ đĩa khả dụng dưới 2 GB
resource "aws_cloudwatch_metric_alarm" "rds_free_storage_low" {
  alarm_name          = "${var.project_name}-rds-free-storage-low-alert"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2147483648 # 2 GB tính theo bytes (2 * 1024 * 1024 * 1024)
  alarm_description   = "Canh bao nguy cap: RDS MySQL dung luong trong con lai duoi 2 GB. Nguy co loi ghi transaction log!"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mysql_primary.identifier
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name       = "${var.project_name}-rds-storage-alarm"
    Tier       = "Database"
    Week       = "Week-4"
    MetricType = "FreeStorageSpace"
  }
}

# Alarm 3: RDS MySQL Bộ nhớ RAM khả dụng dưới 64 MB
resource "aws_cloudwatch_metric_alarm" "rds_freeable_memory_low" {
  alarm_name          = "${var.project_name}-rds-freeable-memory-low-alert"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 67108864 # 64 MB tính theo bytes
  alarm_description   = "Canh bao bo nho: RDS MySQL bo nho RAM Freeable duoi 64 MB. Canh bao can kiet tai nguyen RAM tren db.t3.micro."

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mysql_primary.identifier
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name       = "${var.project_name}-rds-memory-alarm"
    Tier       = "Database"
    Week       = "Week-4"
    MetricType = "FreeableMemory"
  }
}

# Alarm 4: Container / Compute Quá tải CPU >= 70% (ECS Fargate hoặc EC2 Compute Tier)
resource "aws_cloudwatch_metric_alarm" "compute_cpu_high" {
  alarm_name          = "${var.project_name}-compute-cpu-high-alert"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_utilization_alarm_threshold # 70%
  alarm_description   = "Canh bao tai tang Compute: ECS Service CPU vuot nguong 70%. Kich hoat kịch ban Auto-scaling hoac kiem tra vong lap vo tan."

  dimensions = {
    ClusterName = "${var.project_name}-cluster"
    ServiceName = "${var.project_name}-backend-service"
  }

  alarm_actions             = [aws_sns_topic.alerts.arn]
  ok_actions                = [aws_sns_topic.alerts.arn]
  insufficient_data_actions = []

  tags = {
    Name       = "${var.project_name}-compute-cpu-alarm"
    Tier       = "Compute"
    Week       = "Week-4"
    MetricType = "CPUUtilization"
  }
}

# Alarm 5: FinOps Ngân sách — Cảnh báo chi phí tích lũy ước tính vượt $20 USD
resource "aws_cloudwatch_metric_alarm" "billing_estimated_charges" {
  alarm_name          = "${var.project_name}-billing-estimated-charges-alert"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 21600 # 6 giờ
  statistic           = "Maximum"
  threshold           = 20.0 # $20 USD (Khớp với Ngưỡng Cảnh báo Cấp 1 của AWS Budgets)
  alarm_description   = "Canh bao FinOps: Chi phi tich luy thang uoc tinh vuot qua $20 USD (10% tong credit $200). Canh giac kiem tra tai nguyen quen tat."

  dimensions = {
    Currency = "USD"
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = {
    Name       = "${var.project_name}-billing-alarm"
    Tier       = "FinOps"
    Week       = "Week-4"
    MetricType = "EstimatedCharges"
  }
}

# ------------------------------------------------------------------------------
# 4. CLOUDWATCH OBSERVABILITY DASHBOARD (TRỰC QUAN HÓA TOÀN BỘ HẠ TẦNG)
# ------------------------------------------------------------------------------
# Dashboard phục vụ trực tiếp Màn 3 trong kịch bản bảo vệ đồ án:
# - Cột 1 & 2: Dữ liệu RDS MySQL (CPU, Connections, Storage, Freeable Memory)
# - Cột 3 & 4: Tầng Tính toán & Container (ECS/EC2 CPU, Memory)
# - Cột 5 & 6: Tầng Mạng & Cổng WAF Defense (ALB Requests, Target Latency, WAF Blocked Requests)
# - Cột 7 & 8: FinOps & Chi phí ước tính (EstimatedCharges, Alarms Status)
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_dashboard" "observability" {
  dashboard_name = "${var.project_name}-observability-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # HÀNG 1: TIÊU ĐỀ & TRẠNG THÁI HỆ THỐNG
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2
        properties = {
          markdown = "# 🏢 ENTERPRISE CLOUD & DEVSECOPS PLATFORM — OBSERVABILITY DASHBOARD\n**Môi trường:** Production (`Multi-AZ`) | **Khu vực:** `${var.aws_region}` | **Chuyên trách:** Thành viên 3 (Dữ liệu & FinOps) | **Ngân sách:** $200 Credit"
        }
      },

      # HÀNG 2: TẦNG DỮ LIỆU — RDS MYSQL METRICS (TRỌNG TÂM THÀNH VIÊN 3)
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.mysql_primary.identifier, { label = "RDS CPU Utilization (%)", color = "#ff7f0e" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "🗄️ RDS MySQL — CPU Utilization (%)"
          period  = 300
          stat    = "Average"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
          annotations = {
            horizontal = [
              {
                value = 70
                label = "Ngưỡng cảnh báo CPU (70%)"
                color = "#d62728"
              }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 6
        y      = 2
        width  = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.mysql_primary.identifier, { label = "Active Connections", color = "#1f77b4" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "🔌 RDS MySQL — Active Database Connections"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 2
        width  = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", aws_db_instance.mysql_primary.identifier, { label = "Free Storage (Bytes)", color = "#2ca02c" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "💾 RDS MySQL — Free Storage Space (Bytes)"
          period  = 300
          stat    = "Average"
          annotations = {
            horizontal = [
              {
                value = 2147483648
                label = "Ngưỡng nguy cấp (2 GB)"
                color = "#d62728"
              }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 18
        y      = 2
        width  = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", aws_db_instance.mysql_primary.identifier, { label = "Freeable Memory (Bytes)", color = "#9467bd" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "🧠 RDS MySQL — Freeable Memory (RAM)"
          period  = 300
          stat    = "Average"
        }
      },

      # HÀNG 3: TẦNG COMPUTE & CỔNG MẠNG ALB / WAF DEFENSE
      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", "${var.project_name}-cluster", "ServiceName", "${var.project_name}-backend-service", { label = "ECS Service CPU (%)", color = "#e377c2" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "⚙️ Compute Tier — ECS Fargate CPU (%)"
          period  = 300
          stat    = "Average"
          annotations = {
            horizontal = [
              {
                value = 70
                label = "Ngưỡng quá tải Container (70%)"
                color = "#d62728"
              }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 6
        y      = 8
        width  = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", { label = "ALB Total Requests", color = "#17becf" }],
            [".", "HTTPCode_Target_5XX_Count", { label = "Target 5XX Errors", color = "#d62728" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "🌐 Network Tier — ALB Request Count & 5XX Errors"
          period  = 300
          stat    = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 8
        width  = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/WAFV2", "BlockedRequests", "WebACL", "${var.project_name}-waf-web-acl", "Region", var.aws_region, "Rule", "ALL", { label = "WAF Blocked Requests", color = "#d62728" }],
            ["...", "AllowedRequests", { label = "WAF Allowed Requests", color = "#2ca02c" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "🛡️ WAF Defense — Blocked vs Allowed Requests (Demo Màn 2)"
          period  = 300
          stat    = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 18
        y      = 8
        width  = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", { label = "Latency (seconds)", color = "#8c564b" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "⏱️ Application — Latency / Target Response Time"
          period  = 300
          stat    = "Average"
        }
      },

      # HÀNG 4: FINOPS QUẢN TRỊ TÀI CHÍNH & TRẠNG THÁI ALARMS TỔNG HỢP
      {
        type   = "metric"
        x      = 0
        y      = 14
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD", { label = "Ước tính chi phí tích lũy ($ USD)", color = "#bcbd22" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1" # Billing metrics luôn nằm ở us-east-1
          title   = "💰 FinOps — Estimated Charges vs $200 Budget Limit"
          period  = 21600
          stat    = "Maximum"
          annotations = {
            horizontal = [
              {
                value = 20
                label = "Cảnh báo Cấp 1: $20 (10%)"
                color = "#ffbb78"
              },
              {
                value = 50
                label = "Cảnh báo Cấp 2: $50 (25%)"
                color = "#ff7f0e"
              },
              {
                value = 200
                label = "Hạn mức tối đa: $200 (100%)"
                color = "#d62728"
              }
            ]
          }
        }
      },
      {
        type   = "alarm"
        x      = 12
        y      = 14
        width  = 12
        height = 6
        properties = {
          title = "🚨 Hệ thống Giám sát Chuông Báo động (CloudWatch Alarms Status)"
          alarms = [
            aws_cloudwatch_metric_alarm.rds_cpu_high.arn,
            aws_cloudwatch_metric_alarm.rds_free_storage_low.arn,
            aws_cloudwatch_metric_alarm.rds_freeable_memory_low.arn,
            aws_cloudwatch_metric_alarm.compute_cpu_high.arn,
            aws_cloudwatch_metric_alarm.billing_estimated_charges.arn
          ]
        }
      }
    ]
  })
}
