# ==========================================
# Production VPC (Multi-AZ Architecture)
# ==========================================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-production-vpc"
    Tier = "Network-Core"
  }
}
