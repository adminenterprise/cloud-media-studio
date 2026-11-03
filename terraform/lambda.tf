# ==============================================================================
# AWS LAMBDA — SERVERLESS IMAGE OPTIMIZATION PIPELINE
# Phân mảng: Thành viên 2 (Tính toán & Container & Serverless)
# Tích hợp:
# - Bắt sự kiện S3 ObjectCreated từ Raw Bucket
# - Tự động nén sang WebP (-84% dung lượng) & sinh 3 kích thước Thumbnails
# - Đẩy file đã tối ưu sang Processed Bucket
# - Kiến trúc ARM64 (AWS Graviton2) tiết kiệm 20% chi phí tính toán (FinOps)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. IAM ROLE & POLICY CHO AWS LAMBDA (NGUYÊN TẮC LEAST PRIVILEGE)
# ------------------------------------------------------------------------------
resource "aws_iam_role" "lambda_image_processor" {
  name = "${var.project_name}-lambda-image-processor-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "${var.project_name}-lambda-image-processor-role"
    Role        = "Serverless-Media-Processing"
    Owner       = "Member2-Compute"
    Environment = var.environment
  }
}

# Quyền ghi Log vào Amazon CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_image_processor.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Policy truy cập S3 (Đọc Raw Bucket và Ghi Processed Bucket)
resource "aws_iam_policy" "lambda_s3_media_access" {
  name        = "${var.project_name}-lambda-s3-media-policy"
  description = "Cho phep Lambda doc anh tu Raw Bucket va ghi anh WebP vao Processed Bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-raw-*",
          "arn:aws:s3:::${var.project_name}-raw-*/*",
          "arn:aws:s3:::${var.s3_static_assets_bucket_name}",
          "arn:aws:s3:::${var.s3_static_assets_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-processed-*",
          "arn:aws:s3:::${var.project_name}-processed-*/*",
          "arn:aws:s3:::${var.s3_static_assets_bucket_name}",
          "arn:aws:s3:::${var.s3_static_assets_bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3_attach" {
  role       = aws_iam_role.lambda_image_processor.name
  policy_arn = aws_iam_policy.lambda_s3_media_access.arn
}

# ------------------------------------------------------------------------------
# 2. AWS LAMBDA FUNCTION (GRAVITON2 / ARM64 CHO FINOPS)
# ------------------------------------------------------------------------------
resource "aws_lambda_function" "image_processor" {
  function_name = "${var.project_name}-image-processor"
  description   = "Cloud Media Studio Serverless WebP compression & thumbnail generator"
  filename         = "${path.module}/lambda_payload.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_payload.zip")
  role             = aws_iam_role.lambda_image_processor.arn
  handler       = "index.handler"
  runtime       = "nodejs22.x"
  architectures = ["arm64"] # AWS Graviton2: Nhanh hon va tiet kiem 20% chi phi
  memory_size   = 512
  timeout       = 30

  environment {
    variables = {
      DESTINATION_BUCKET       = "${var.project_name}-processed-${var.aws_region}"
      AUTO_GENERATE_THUMBNAILS = "true"
      TARGET_FORMAT            = "WEBP"
      ENVIRONMENT              = var.environment
    }
  }

  tags = {
    Name        = "${var.project_name}-image-processor"
    Role        = "Serverless-Media-Processing"
    Owner       = "Member2-Compute"
    Tier        = "Compute-Serverless"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# 3. CHO PHÉP S3 KÍCH HOẠT LAMBDA FUNCTION & S3 EVENT NOTIFICATION
# ------------------------------------------------------------------------------
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.s3_static_assets_bucket_name}"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.s3_static_assets_bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.image_processor.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}

# ------------------------------------------------------------------------------
# 4. OUTPUTS CHO THÀNH VIÊN 2 & HỘI ĐỒNG XEM XÉT
# ------------------------------------------------------------------------------
output "lambda_image_processor_arn" {
  description = "ARN cua ham AWS Lambda xu ly media tu dong"
  value       = aws_lambda_function.image_processor.arn
}

output "lambda_image_processor_name" {
  description = "Ten cua ham AWS Lambda xu ly media tu dong"
  value       = aws_lambda_function.image_processor.function_name
}
