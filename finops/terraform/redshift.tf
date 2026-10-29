# ==============================================================================
# AMAZON REDSHIFT SERVERLESS — TUẦN 5: PHÂN TÍCH DỮ LIỆU NÂNG CAO (DEMO 1–2 GIỜ)
# ==============================================================================
# Phân mảng: Thành viên 3 (Dữ liệu & FinOps — Phạm Thế Hùng)
#
# ⚠️  CẢNH BÁO FINOPS: TÀI NGUYÊN NÀY CHỈ DÙNG CHO DEMO 1–2 GIỜ!
# ⚠️  SAU KHI CHỤP ẢNH MINH CHỨNG, BẮT BUỘC CHẠY: terraform destroy -target
# ⚠️  HOẶC ĐẶT enable_redshift_demo = false VÀ terraform apply ĐỂ XÓA NGAY!
#
# Mục tiêu:
# 1. Khởi tạo Redshift Serverless Namespace (database analytics) và Workgroup (compute 8 RPU tối thiểu)
# 2. Nạp dữ liệu mẫu e-commerce và chạy câu truy vấn phân tích (Revenue, Top Products, Cohort)
# 3. Chụp ảnh minh chứng kết quả truy vấn trên Redshift Query Editor v2
# 4. XÓA NGAY LẬP TỨC workgroup + namespace để bảo toàn credit $200
#
# Chi phí ước tính:
# - Redshift Serverless tính phí theo RPU-giờ: ~$0.375/RPU-giờ (Base 8 RPU)
# - Demo 1 giờ: ~$3.00 USD | Demo 2 giờ: ~$6.00 USD
# - IDLE (không chạy query): TỰ ĐỘNG TẮT compute sau thời gian chờ (FinOps tối ưu)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. SECURITY GROUP CHO REDSHIFT SERVERLESS (Port 5439)
# ------------------------------------------------------------------------------
resource "aws_security_group" "redshift" {
  count       = var.enable_redshift_demo ? 1 : 0
  name_prefix = "${var.project_name}-redshift-sg-"
  description = "Security Group cho Redshift Serverless - Chi cho phep ket noi noi bo tu Private Subnets (Port 5439)"
  vpc_id      = var.vpc_id

  # Inbound: Port 5439 từ Private App Subnets (kết nối query từ backend hoặc bastion)
  ingress {
    description = "Redshift Serverless tu Private App Subnets"
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = var.private_app_subnet_cidrs
  }

  # Outbound: Cho phép tất cả (Redshift cần gọi AWS API, S3, CloudWatch)
  egress {
    description = "Cho phep tat ca outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name       = "${var.project_name}-redshift-serverless-sg"
    Tier       = "Analytics"
    Week       = "Week-5"
    CostCenter = "Member3-Data-FinOps"
    Ephemeral  = "true"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ------------------------------------------------------------------------------
# 2. IAM ROLE CHO REDSHIFT SERVERLESS (Truy cập S3 đọc dữ liệu mẫu)
# ------------------------------------------------------------------------------
resource "aws_iam_role" "redshift_serverless" {
  count       = var.enable_redshift_demo ? 1 : 0
  name_prefix = "${var.project_name}-redshift-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "redshift-serverless.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name       = "${var.project_name}-redshift-serverless-role"
    Week       = "Week-5"
    CostCenter = "Member3-Data-FinOps"
  }
}

resource "aws_iam_role_policy" "redshift_s3_access" {
  count = var.enable_redshift_demo ? 1 : 0
  name  = "${var.project_name}-redshift-s3-access"
  role  = aws_iam_role.redshift_serverless[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetBucketAcl",
          "s3:GetBucketCors",
          "s3:GetEncryptionConfiguration",
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListAllMyBuckets",
          "s3:ListMultipartUploadParts",
          "s3:ListBucketMultipartUploads"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# 3. REDSHIFT SERVERLESS NAMESPACE (Database Configuration)
# ------------------------------------------------------------------------------
resource "aws_redshiftserverless_namespace" "analytics" {
  count               = var.enable_redshift_demo ? 1 : 0
  namespace_name      = "${var.project_name}-analytics-ns"
  db_name             = var.redshift_db_name
  admin_username      = var.redshift_admin_username
  admin_user_password = var.redshift_admin_password
  iam_roles           = [aws_iam_role.redshift_serverless[0].arn]

  # FinOps: Không tạo final snapshot khi destroy (tài nguyên demo tạm thời)
  log_exports = ["userlog", "connectionlog"]

  tags = {
    Name       = "${var.project_name}-redshift-analytics-namespace"
    Tier       = "Analytics"
    Week       = "Week-5"
    CostCenter = "Member3-Data-FinOps"
    Ephemeral  = "true"
    MaxRuntime = "2-hours"
  }
}

# ------------------------------------------------------------------------------
# 4. REDSHIFT SERVERLESS WORKGROUP (Compute Configuration — 8 RPU tối thiểu)
# ------------------------------------------------------------------------------
resource "aws_redshiftserverless_workgroup" "analytics" {
  count          = var.enable_redshift_demo ? 1 : 0
  namespace_name = aws_redshiftserverless_namespace.analytics[0].namespace_name
  workgroup_name = "${var.project_name}-analytics-wg"
  base_capacity  = var.redshift_base_capacity_rpu # 8 RPU tối thiểu (FinOps)

  # Sử dụng Private DB Subnets từ VPC của Member 1
  subnet_ids         = var.redshift_subnet_ids
  security_group_ids = [aws_security_group.redshift[0].id]

  # Truy cập công khai: BẬT tạm cho Query Editor v2 trên Console (demo chụp ảnh)
  publicly_accessible = var.redshift_publicly_accessible

  tags = {
    Name       = "${var.project_name}-redshift-analytics-workgroup"
    Tier       = "Analytics"
    Week       = "Week-5"
    CostCenter = "Member3-Data-FinOps"
    Ephemeral  = "true"
    MaxRuntime = "2-hours"
  }

  depends_on = [aws_redshiftserverless_namespace.analytics]
}
