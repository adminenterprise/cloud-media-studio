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
