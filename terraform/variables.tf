# ==========================================
# General Project Variables
# ==========================================
variable "aws_region" {
  description = "AWS region for deploying resources"
  type        = string
  default     = "ap-southeast-1" # Singapore - Độ trễ thấp nhất cho VN
}

variable "project_name" {
  description = "Project name identifier used in resource tags and prefixes"
  type        = string
  default     = "cloud-media-studio"
}

variable "environment" {
  description = "Deployment environment (production, staging, dev)"
  type        = string
  default     = "production"
}

# ==========================================
# VPC & Subnet Networking Variables
# ==========================================
variable "vpc_cidr" {
  description = "CIDR block for the Production VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Multi-AZ list for High Availability deployment"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for Public Subnets (Edge Tier - ALB, NAT GW)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for Private App Subnets (Compute Tier - EC2 ASG, ECS Fargate)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for Private DB Subnets (Database Tier - RDS, Aurora - Isolated)"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}

# ==========================================
# FinOps Cost-Optimization Switches
# ==========================================
variable "enable_nat_gateway" {
  description = "Toggle NAT Gateway creation (set false when not testing compute to save ~$0.045/hr from $200 credit)"
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway across all AZs instead of one per AZ (Saves ~50% NAT cost)"
  type        = bool
  default     = true
}

# ==========================================
# Security Group Variables (Tuần 2)
# ==========================================
variable "app_port" {
  description = "Application port for backend server (NodeJS default: 3000)"
  type        = number
  default     = 3000
}

variable "efs_file_system_id" {
  default     = "fs-0b619655013598e7e"
  description = "Existing Amazon EFS file system ID mounted by the Week 2 EC2 instances"
  type        = string
}

variable "db_port" {
  description = "Database port for RDS MySQL/Aurora (MySQL default: 3306)"
  type        = number
  default     = 3306
}

variable "admin_ip" {
  description = "Admin IP CIDR for Bastion Host SSH access (e.g., '203.0.113.10/32'). Use /32 for single IP."
  type        = string
  default     = "0.0.0.0/0" # TODO: Thay bằng IP thật của quản trị viên trước khi deploy production
}

# ==========================================
# CloudFront & S3 Origin Variables (Tuần 3)
# ==========================================
variable "s3_static_assets_bucket_name" {
  description = "Tên S3 Bucket lưu trữ tài nguyên tĩnh từ Member 3"
  type        = string
  default     = "enterprise-cloud-devsecops-static-assets-ap-southeast-1"
}

variable "alb_dns_name" {
  description = "DNS name của Application Load Balancer từ Member 2 (để trống nếu chưa tạo ALB)"
  type        = string
  default     = ""
}

# ==========================================
# Route 53 DNS Variables (Tuần 3)
# ==========================================
variable "enable_route53" {
  description = "Bật/Tắt Route 53 Hosted Zone & Records (Mặc định false để tối ưu FinOps $0.50/tháng nếu chưa mua domain)"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Tên miền tùy chỉnh (e.g., devsecops-enterprise.com). Để trống nếu dùng domain CloudFront mặc định"
  type        = string
  default     = ""
}

# ==========================================
# ALB & AWS WAFv2 Variables
# ==========================================
variable "enable_alb" {
  description = "Create the public Application Load Balancer and target groups (enable for Member 2, Week 2)"
  type        = bool
  default     = false
}

variable "enable_waf" {
  description = "Create and associate AWS WAFv2 with the ALB (enable for security testing; incurs additional cost)"
  type        = bool
  default     = false
}

# Backward compatibility for existing terraform.tfvars files.
# Setting this legacy switch to true enables both ALB and WAF.
variable "enable_alb_and_waf" {
  description = "Bật/Tắt ALB và AWS WAFv2 (FinOps: false khi không test để tiết kiệm ~$0.0225/h và phí WAF từ $200 credit)"
  type        = bool
  default     = false
}

variable "enable_alb_deletion_protection" {
  description = "Bật/Tắt bảo vệ xóa ALB (FinOps: Đặt false trong giai đoạn sinh viên để dễ destroy)"
  type        = bool
  default     = false
}

variable "waf_rate_limit" {
  description = "Số lượng request tối đa từ một IP trong chu kỳ 5 phút trước khi bị WAF chặn (Đồ án yêu cầu: 100 req/5 phút)"
  type        = number
  default     = 100
}

# ==========================================
# Multi-VPC & Peering Variables (Tuần 5)
# ==========================================
variable "management_vpc_cidr" {
  description = "CIDR block cho Management / DevSecOps VPC thứ 2 (Không trùng với Production VPC 10.0.0.0/16)"
  type        = string
  default     = "10.1.0.0/16"
}

variable "management_subnet_cidrs" {
  description = "CIDR blocks cho Management Subnets (Nơi đặt Bastion Host / CI-CD Runners)"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}


