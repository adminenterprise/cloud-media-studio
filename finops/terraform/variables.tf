variable "aws_region" {
  description = "AWS Region triển khai hạ tầng FinOps"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Tên dự án doanh nghiệp"
  type        = string
  default     = "enterprise-cloud-devsecops"
}

variable "environment" {
  description = "Môi trường triển khai"
  type        = string
  default     = "production"
}

variable "budget_limit_usd" {
  description = "Tổng hạn mức gói credit sinh viên ($200 USD)"
  type        = string
  default     = "200.0"
}

variable "alert_threshold_1_percent" {
  description = "Ngưỡng cảnh báo Cấp 1 (10% tương đương $20 USD)"
  type        = number
  default     = 10.0
}

variable "alert_threshold_2_percent" {
  description = "Ngưỡng cảnh báo Cấp 2 (25% tương đương $50 USD)"
  type        = number
  default     = 25.0
}

variable "alert_threshold_forecast_percent" {
  description = "Ngưỡng cảnh báo dự báo (80% tương đương $160 USD)"
  type        = number
  default     = 80.0
}

variable "notification_emails" {
  description = "Danh sách email nhận thông báo cảnh báo từ AWS Budgets"
  type        = list(string)
  default     = ["minhquan10092006@gmail.com"]
}

variable "member_users" {
  description = "Danh sách username IAM cho 4 thành viên theo phân mảng"
  type = map(object({
    username = string
    role     = string
  }))
  default = {
    member1 = {
      username = "member1-network-iac"
      role     = "Network and Infrastructure as Code Lead"
    }
    member2 = {
      username = "member2-compute-container"
      role     = "Compute and Container Specialist"
    }
    member3 = {
      username = "member3-data-finops"
      role     = "Database Storage and FinOps Specialist"
    }
    member4 = {
      username = "member4-security-devsecops"
      role     = "Security Compliance and DevSecOps Specialist"
    }
  }
}
