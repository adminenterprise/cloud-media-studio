# ==============================================================================
# AWS CLOUDTRAIL — TUẦN 4: GHI VẾT KIỂM TOÁN HẠ TẦNG (AUDIT TRAIL LOGGING)
# ==============================================================================
# Phân mảng: Thành viên 3 (Dữ liệu & FinOps — Phạm Thế Hùng)
# Mục tiêu:
# 1. Ghi vết kiểm toán (Audit Trail) 100% các hành vi gọi API quản trị trên tài khoản AWS
# 2. Lưu trữ vết kiểm toán vào S3 Bucket chuyên dụng, mã hóa SSE-S3 và chặn toàn bộ Public Access
# 3. Áp dụng FinOps S3 Lifecycle: Tự động chuyển audit log sang S3 Glacier sau 30 ngày và xóa sau 90 ngày
# 4. Tích hợp CloudWatch Log Group: Đẩy log kiểm toán thời gian thực phục vụ giám sát và cảnh báo bảo mật
# ==============================================================================

# Lấy AWS Account ID hiện tại để đặt tên S3 Bucket duy nhất toàn cầu
data "aws_caller_identity" "current" {}

# ------------------------------------------------------------------------------
# 1. S3 BUCKET LƯU TRỮ VẾT KIỂM TOÁN CLOUDTRAIL
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "cloudtrail_audit" {
  bucket        = "${var.project_name}-cloudtrail-audit-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
  force_destroy = true # Cho phép dọn dẹp sạch sẽ khi nghiệm thu kết thúc đồ án

  tags = {
    Name       = "${var.project_name}-cloudtrail-audit-bucket"
    Tier       = "Security-Governance"
    Week       = "Week-4"
    Compliance = "AWS-Well-Architected-Security"
    CostCenter = "Member3-Data-FinOps"
  }
}

# Chặn 100% truy cập công khai vào S3 Bucket lưu vết kiểm toán (Tuyệt đối bảo mật)
resource "aws_s3_bucket_public_access_block" "cloudtrail_audit" {
  bucket = aws_s3_bucket.cloudtrail_audit.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Mã hóa dữ liệu at-rest chuẩn SSE-S3 (AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_audit" {
  bucket = aws_s3_bucket.cloudtrail_audit.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bật tính năng quản lý phiên bản (Versioning) để bảo vệ tính toàn vẹn của tệp kiểm toán
resource "aws_s3_bucket_versioning" "cloudtrail_audit" {
  bucket = aws_s3_bucket.cloudtrail_audit.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ------------------------------------------------------------------------------
# 2. FINOPS S3 LIFECYCLE CHO CLOUDTRAIL LOGS (TIẾT KIỆM CHI PHÍ LƯU TRỮ AUDIT)
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_audit" {
  bucket     = aws_s3_bucket.cloudtrail_audit.id
  depends_on = [aws_s3_bucket_versioning.cloudtrail_audit]

  # Quy tắc 1: Chuyển audit logs cũ sang S3 Glacier Flexible Retrieval sau 30 ngày (Tiết kiệm >84%)
  rule {
    id     = "archive-cloudtrail-logs-to-glacier-after-30-days"
    status = "Enabled"

    filter {
      prefix = "AWSLogs/"
    }

    transition {
      days          = var.cloudtrail_s3_glacier_transition_days # 30 ngày
      storage_class = "GLACIER"
    }

    # Hạn chế lưu trữ vĩnh viễn gây tốn credit sinh viên ($200)
    expiration {
      days = var.cloudtrail_s3_retention_days # 90 ngày tự động xóa log cũ
    }

    # Tự động dọn dẹp các multipart upload dở dang sau 7 ngày
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  # Quy tắc 2: Dọn dẹp phiên bản cũ không hiện hành (Noncurrent Versions)
  rule {
    id     = "expire-noncurrent-audit-log-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# ------------------------------------------------------------------------------
# 3. S3 BUCKET POLICY CHO PHÉP CLOUDTRAIL GHI LOG (CHUẨN AWS SECURITY)
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "cloudtrail_audit" {
  bucket = aws_s3_bucket.cloudtrail_audit.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Quyền 1: Cho phép CloudTrail kiểm tra ACL của bucket
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_audit.arn
        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${var.project_name}-audit-trail"
          }
        }
      },
      # Quyền 2: Cho phép CloudTrail ghi log vào đường dẫn AWSLogs/
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_audit.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"  = "bucket-owner-full-control"
            "aws:SourceArn" = "arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${var.project_name}-audit-trail"
          }
        }
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# 4. IAM ROLE & POLICY CHO CLOUDTRAIL ĐẨY LOG SANG CLOUDWATCH LOGS
# ------------------------------------------------------------------------------
resource "aws_iam_role" "cloudtrail_to_cloudwatch" {
  name_prefix = "${var.project_name}-cloudtrail-cw-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name       = "${var.project_name}-cloudtrail-to-cloudwatch-role"
    Week       = "Week-4"
    CostCenter = "Member3-Data-FinOps"
  }
}

resource "aws_iam_policy" "cloudtrail_to_cloudwatch" {
  name_prefix = "${var.project_name}-cloudtrail-cw-policy-"
  description = "Cho phep CloudTrail tao log stream va ghi log events vao CloudWatch Log Group"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudtrail_to_cloudwatch" {
  role       = aws_iam_role.cloudtrail_to_cloudwatch.name
  policy_arn = aws_iam_policy.cloudtrail_to_cloudwatch.arn
}

# ------------------------------------------------------------------------------
# 5. AWS CLOUDTRAIL TRAIL (AUDIT LOGGING ENGINE)
# ------------------------------------------------------------------------------
resource "aws_cloudtrail" "main" {
  name                          = "${var.project_name}-audit-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_audit.id
  s3_key_prefix                 = ""
  include_global_service_events = true
  is_multi_region_trail         = var.cloudtrail_is_multi_region # false mặc định (FinOps tiết kiệm cho khu vực chính)
  enable_log_file_validation    = true                           # Kiểm tra tính toàn vẹn chữ ký hash, chống sửa đổi log

  # Đẩy log vào CloudWatch Log Group để theo dõi & cảnh báo thời gian thực
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_to_cloudwatch.arn

  # Ghi vết toàn bộ sự kiện quản trị (Management Events: Read/Write)
  # Lưu ý FinOps: Management Events đầu tiên trên mỗi trail là HOÀN TOÀN MIỄN PHÍ!
  event_selector {
    read_write_type           = "All"
    include_management_events = true

    # Không kích hoạt Data Events S3 để tránh phát sinh chi phí theo số lượng request đọc ghi S3
  }

  tags = {
    Name       = "${var.project_name}-audit-trail"
    Tier       = "Security-Governance"
    Week       = "Week-4"
    CostCenter = "Member3-Data-FinOps"
  }

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_audit,
    aws_iam_role_policy_attachment.cloudtrail_to_cloudwatch
  ]
}
