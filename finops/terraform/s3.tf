# ==============================================================================
# AMAZON S3 BUCKET — TUẦN 2: LƯU TRỮ TÀI NGUYÊN TĨNH
# ==============================================================================
# S3 Bucket lưu trữ ảnh đại diện, CSS, JS, tài liệu tải lên
# Bảo mật: Mã hóa SSE-S3 (AES256) + Block All Public Access
# Chi phí: MIỄN PHÍ (Free Tier < 5GB)

# ------------------------------------------------------------------------------
# 1. S3 BUCKET CHÍNH
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "static_assets" {
  bucket = "${var.project_name}-static-assets-${var.aws_region}"

  tags = {
    Name       = "${var.project_name}-static-assets"
    Tier       = "Storage"
    Week       = "Week-2"
    CostCenter = "Member3-Data-FinOps"
  }
}

# ------------------------------------------------------------------------------
# 2. MÃ HÓA SSE-S3 (Bắt buộc theo yêu cầu Deliverable Tuần 2)
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # SSE-S3: Miễn phí, không cần KMS key
    }
    bucket_key_enabled = true
  }
}

# ------------------------------------------------------------------------------
# 3. BLOCK ALL PUBLIC ACCESS (Bảo mật chuẩn Enterprise)
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------
# 4. VERSIONING (Bảo vệ dữ liệu — Phục hồi file bị xóa nhầm)
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_versioning" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ------------------------------------------------------------------------------
# 5. CORS CONFIGURATION (Cho phép Frontend truy cập tài nguyên tĩnh)
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_cors_configuration" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"] # Tuần 3+ sẽ lock chỉ cho phép CloudFront domain
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}

# ------------------------------------------------------------------------------
# 6. CẤU TRÚC THƯ MỤC MẶC ĐỊNH (Tạo sẵn folder cho team)
# ------------------------------------------------------------------------------
resource "aws_s3_object" "folder_images" {
  bucket  = aws_s3_bucket.static_assets.id
  key     = "images/"
  content = ""
}

resource "aws_s3_object" "folder_css" {
  bucket  = aws_s3_bucket.static_assets.id
  key     = "css/"
  content = ""
}

resource "aws_s3_object" "folder_js" {
  bucket  = aws_s3_bucket.static_assets.id
  key     = "js/"
  content = ""
}

resource "aws_s3_object" "folder_uploads" {
  bucket  = aws_s3_bucket.static_assets.id
  key     = "uploads/"
  content = ""
}

resource "aws_s3_object" "folder_documents" {
  bucket  = aws_s3_bucket.static_assets.id
  key     = "documents/"
  content = ""
}

# ------------------------------------------------------------------------------
# 7. S3 LIFECYCLE CONFIGURATION — TUẦN 3: TỐI ƯU CHI PHÍ VỚI S3 GLACIER (FINOPS)
# ------------------------------------------------------------------------------
# Tiết kiệm chi phí lưu trữ dài hạn:
# - S3 Standard: ~$0.025 / GB / tháng
# - S3 Glacier Flexible Retrieval: ~$0.004 / GB / tháng (Tiết kiệm > 84% chi phí)
resource "aws_s3_bucket_lifecycle_configuration" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  # Quy tắc 1: Tự động chuyển tài liệu cũ / tệp uploads sang S3 Glacier sau 30 ngày
  rule {
    id     = "archive-uploads-to-glacier-after-30-days"
    status = "Enabled"

    filter {
      prefix = "uploads/"
    }

    transition {
      days          = var.s3_glacier_transition_days
      storage_class = "GLACIER"
    }
  }

  # Quy tắc 2: Tự động chuyển tài liệu trong thư mục documents/ sang Glacier sau 30 ngày
  rule {
    id     = "archive-documents-to-glacier-after-30-days"
    status = "Enabled"

    filter {
      prefix = "documents/"
    }

    transition {
      days          = var.s3_glacier_transition_days
      storage_class = "GLACIER"
    }
  }

  # Quy tắc 3: Quản lý các phiên bản cũ (Noncurrent Versions) — tránh tốn chi phí rác
  rule {
    id     = "manage-noncurrent-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_transition {
      noncurrent_days = var.s3_glacier_transition_days
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = var.s3_noncurrent_version_expiration_days
    }
  }

  # Quy tắc 4: Tự động hủy các phiên tải lên nhiều phần (Multipart Upload) chưa hoàn tất sau 7 ngày
  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
