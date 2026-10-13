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

# ==============================================================================
# TUẦN 2: BIẾN CẤU HÌNH RDS MYSQL (MEMBER 3 — DỮ LIỆU & FINOPS)
# ==============================================================================

variable "vpc_id" {
  description = "VPC ID từ Member 1 (chạy: cd terraform/ && terraform output vpc_id)"
  type        = string
}

variable "rds_db_subnet_group_name" {
  description = "RDS DB Subnet Group Name từ Member 1 (terraform output rds_db_subnet_group_name)"
  type        = string
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks của Private App Subnets — dùng cho Security Group rule (port 3306)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "rds_engine_version" {
  description = "Phiên bản MySQL Engine"
  type        = string
  default     = "8.0"
}

variable "rds_instance_class" {
  description = "Instance class cho RDS (db.t3.micro = ~$0.018/hr — FinOps optimized)"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Dung lượng ổ đĩa ban đầu (GB)"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Dung lượng ổ đĩa tối đa khi auto-scale (GB)"
  type        = number
  default     = 50
}

variable "rds_db_name" {
  description = "Tên database mặc định khởi tạo khi tạo RDS instance"
  type        = string
  default     = "enterprise_db"
}

variable "rds_master_username" {
  description = "Tài khoản admin RDS MySQL"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "rds_master_password" {
  description = "Mật khẩu admin RDS MySQL (Tuần 4: Member 4 sẽ chuyển sang AWS Secrets Manager)"
  type        = string
  sensitive   = true
}

variable "rds_multi_az" {
  description = "Bật Multi-AZ cho High Availability (false = tiết kiệm dev/test, true = bật khi demo bảo vệ)"
  type        = bool
  default     = false
}
