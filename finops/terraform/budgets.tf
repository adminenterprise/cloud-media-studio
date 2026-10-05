# ==============================================================================
# AWS BUDGETS: KIỂM SOÁT NGÂN SÁCH $200 & CẢNH BÁO EMAIL TỰ ĐỘNG (FINOPS TỰ ĐỘNG)
# ==============================================================================

resource "aws_budgets_budget" "student_credit_budget" {
  name              = "${var.project_name}-budget-200usd"
  budget_type       = "COST"
  limit_amount      = var.budget_limit_usd
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2026-01-01_00:00"

  cost_types {
    include_credit             = false
    include_discount           = true
    include_other_subscription = true
    include_recurring          = true
    include_refund             = false
    include_subscription       = true
    include_support            = true
    include_tax                = true
    include_upfront            = true
    use_blended                = false
  }

  # Cảnh báo Cấp 1: Chi tiêu thực tế (ACTUAL) đạt $20 (10% của $200)
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.alert_threshold_1_percent
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.notification_emails
  }

  # Cảnh báo Cấp 2: Chi tiêu thực tế (ACTUAL) đạt $50 (25% của $200) - Báo động khẩn cấp
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.alert_threshold_2_percent
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.notification_emails
  }

  # Cảnh báo Dự báo: Chi phí dự kiến cuối tháng (FORECASTED) chạm 80% ($160)
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = var.alert_threshold_forecast_percent
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.notification_emails
  }
}
