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
  default     = "enterprise-cloud-devsecops"
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
  default     = true
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
