# ==============================================================================
# OUTPUTS: KẾT QUẢ BÀN GIAO FINOPS & IAM (MEMBER 3 DELIVERABLES)
# ==============================================================================

# 1. AWS BUDGETS SPECIFICATION
output "budget_name" {
  description = "Tên cấu hình AWS Budgets kiểm soát chi phí sinh viên"
  value       = aws_budgets_budget.student_credit_budget.name
}

output "budget_limit_usd" {
  description = "Hạn mức tối đa ngân sách ($200 USD)"
  value       = "${aws_budgets_budget.student_credit_budget.limit_amount} ${aws_budgets_budget.student_credit_budget.limit_unit}"
}

output "budget_alerts" {
  description = "Các ngưỡng cảnh báo tự động gửi email"
  value = [
    "Cảnh báo Cấp 1: Chi tiêu thực tế đạt ${var.alert_threshold_1_percent}% ($20 USD)",
    "Cảnh báo Cấp 2 (Khẩn cấp): Chi tiêu thực tế đạt ${var.alert_threshold_2_percent}% ($50 USD)",
    "Cảnh báo Dự báo: Chi phí dự kiến tháng đạt ${var.alert_threshold_forecast_percent}% ($160 USD)"
  ]
}

output "budget_notification_emails" {
  description = "Danh sách email nhận thông báo cảnh báo chi phí"
  value       = var.notification_emails
}

# 2. IAM USERS & GROUPS SPECIFICATION
output "iam_users" {
  description = "Danh sách 4 tài khoản IAM phân quyền theo nguyên tắc Least Privilege"
  value = {
    member1 = {
      name  = aws_iam_user.member1.name
      arn   = aws_iam_user.member1.arn
      group = aws_iam_group.network_iac.name
      track = "Network & IaC Lead"
    }
    member2 = {
      name  = aws_iam_user.member2.name
      arn   = aws_iam_user.member2.arn
      group = aws_iam_group.compute_container.name
      track = "Compute & Container"
    }
    member3 = {
      name  = aws_iam_user.member3.name
      arn   = aws_iam_user.member3.arn
      group = aws_iam_group.data_finops.name
      track = "Data, Storage & FinOps"
    }
    member4 = {
      name  = aws_iam_user.member4.name
      arn   = aws_iam_user.member4.arn
      group = aws_iam_group.security_devsecops.name
      track = "Security & DevSecOps"
    }
  }
}

output "iam_groups" {
  description = "Danh sách các IAM Groups chuyên môn"
  value = [
    aws_iam_group.network_iac.name,
    aws_iam_group.compute_container.name,
    aws_iam_group.data_finops.name,
    aws_iam_group.security_devsecops.name
  ]
}

output "iam_console_login_hint" {
  description = "Đường dẫn đăng nhập IAM Console"
  value       = "https://<your-aws-account-id>.signin.aws.amazon.com/console"
}

# ==============================================================================
# TUẦN 2: RDS MYSQL OUTPUTS — BÀN GIAO CHO MEMBER 2 & MEMBER 4
# ==============================================================================
output "rds_endpoint" {
  description = "RDS MySQL Endpoint đầy đủ (Bàn giao cho Member 2 cấu hình DB_HOST)"
  value       = aws_db_instance.mysql_primary.endpoint
}

output "rds_address" {
  description = "RDS MySQL Address (hostname only, không có port)"
  value       = aws_db_instance.mysql_primary.address
}

output "rds_port" {
  description = "RDS MySQL Port (mặc định 3306)"
  value       = aws_db_instance.mysql_primary.port
}

output "rds_db_name" {
  description = "Tên database mặc định đã khởi tạo"
  value       = aws_db_instance.mysql_primary.db_name
}

output "rds_identifier" {
  description = "RDS Instance Identifier (dùng cho lệnh stop/start CLI tiết kiệm credit)"
  value       = aws_db_instance.mysql_primary.identifier
}

output "rds_security_group_id" {
  description = "Security Group ID của RDS (Dùng từ Member 1 hoặc tự tạo)"
  value       = var.db_security_group_id != "" ? var.db_security_group_id : try(aws_security_group.rds[0].id, "")
}

# ==============================================================================
# TUẦN 2: S3 STATIC ASSETS OUTPUTS
# ==============================================================================
output "s3_static_assets_bucket" {
  description = "Tên S3 Bucket tài nguyên tĩnh"
  value       = aws_s3_bucket.static_assets.id
}

output "s3_static_assets_arn" {
  description = "ARN của S3 Bucket (dùng cho IAM Policy và CloudFront OAI Tuần 3)"
  value       = aws_s3_bucket.static_assets.arn
}

output "s3_static_assets_domain" {
  description = "Regional Domain Name của S3 Bucket (dùng cho CloudFront Origin)"
  value       = aws_s3_bucket.static_assets.bucket_regional_domain_name
}

# ==============================================================================
# TUẦN 3: DYNAMODB & S3 LIFECYCLE OUTPUTS — BÀN GIAO CHO MEMBER 2 & MEMBER 4
# ==============================================================================
output "dynamodb_user_sessions_table_name" {
  description = "Tên bảng DynamoDB User Sessions (Bàn giao cho Member 2 cấu hình DYNAMODB_TABLE_SESSION)"
  value       = aws_dynamodb_table.user_sessions.name
}

output "dynamodb_user_sessions_table_arn" {
  description = "ARN bảng DynamoDB User Sessions (Dùng cho IAM Policy của Member 2 & ECS Task Role của Member 4)"
  value       = aws_dynamodb_table.user_sessions.arn
}

output "dynamodb_cart_table_name" {
  description = "Tên bảng DynamoDB Shopping Cart (Bàn giao cho Member 2 cấu hình DYNAMODB_TABLE_CART)"
  value       = aws_dynamodb_table.cart.name
}

output "dynamodb_cart_table_arn" {
  description = "ARN bảng DynamoDB Shopping Cart (Dùng cho IAM Policy của Member 2 & ECS Task Role của Member 4)"
  value       = aws_dynamodb_table.cart.arn
}

output "s3_lifecycle_status" {
  description = "Trạng thái cấu hình S3 Lifecycle tự động chuyển sang Glacier sau 30 ngày"
  value       = "S3 Lifecycle Configuration ACTIVE: Transitions uploads/* and documents/* to S3 GLACIER after ${var.s3_glacier_transition_days} days | Noncurrent versions to GLACIER after ${var.s3_glacier_transition_days} days and expire after ${var.s3_noncurrent_version_expiration_days} days"
}

# ==============================================================================
# TUẦN 4: THÔNG SỐ BÀN GIAO CLOUDWATCH & CLOUDTRAIL (MEMBER 3)
# ==============================================================================

output "cloudwatch_dashboard_name" {
  description = "Tên CloudWatch Observability Dashboard tập trung"
  value       = aws_cloudwatch_dashboard.observability.dashboard_name
}

output "cloudwatch_dashboard_url" {
  description = "Đường dẫn trực tiếp truy cập CloudWatch Dashboard trên AWS Console"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.observability.dashboard_name}"
}

output "sns_alerts_topic_arn" {
  description = "SNS Topic ARN phát cảnh báo hệ thống và quá tải CPU"
  value       = aws_sns_topic.alerts.arn
}

output "cloudwatch_rds_cpu_alarm_name" {
  description = "Tên CloudWatch Alarm giám sát quá tải RDS MySQL CPU >= 70%"
  value       = aws_cloudwatch_metric_alarm.rds_cpu_high.alarm_name
}

output "cloudwatch_rds_cpu_alarm_arn" {
  description = "ARN của CloudWatch Alarm giám sát RDS CPU"
  value       = aws_cloudwatch_metric_alarm.rds_cpu_high.arn
}

output "cloudwatch_compute_cpu_alarm_name" {
  description = "Tên CloudWatch Alarm giám sát quá tải Compute / Container CPU >= 70%"
  value       = aws_cloudwatch_metric_alarm.compute_cpu_high.alarm_name
}

output "cloudwatch_log_group_backend" {
  description = "CloudWatch Log Group cho Container Backend bàn giao cho Member 2"
  value       = aws_cloudwatch_log_group.app_backend.name
}

output "cloudtrail_trail_name" {
  description = "Tên AWS CloudTrail Trail ghi vết kiểm toán"
  value       = aws_cloudtrail.main.name
}

output "cloudtrail_trail_arn" {
  description = "ARN của AWS CloudTrail Trail"
  value       = aws_cloudtrail.main.arn
}

output "cloudtrail_s3_bucket_name" {
  description = "Tên S3 Bucket lưu trữ vết kiểm toán CloudTrail Audit Logs"
  value       = aws_s3_bucket.cloudtrail_audit.id
}

output "cloudtrail_s3_bucket_arn" {
  description = "ARN của S3 Bucket lưu vết kiểm toán CloudTrail"
  value       = aws_s3_bucket.cloudtrail_audit.arn
}

