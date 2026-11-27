# ==============================================================================
# AWS LAMBDA — SERVERLESS WEBP IMAGE PROCESSOR & PRESIGNED S3 CLOUD API
# Phân mảng: Thành viên 2 (Tính toán & Container & Serverless)
# Tích hợp:
# - Hàm 1 (image_processor): Bắt sự kiện S3 ObjectCreated (prefix: uploads/),
#   chạy thư viện `sharp` trên ARM64 Graviton2 nén ra file `.webp` thật vào
#   `processed/` và sinh 3 ảnh Thumbnail thật (`320w`, `768w`, `1200w`).
# - Hàm 2 (media_api): Cung cấp Lambda Function URL HTTPS cấp phát S3 Presigned
#   PUT URL (SigV4), đọc danh sách file S3 thật và chuyển lớp S3 Glacier IR.
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

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_image_processor.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "lambda_s3_media_access" {
  name        = "${var.project_name}-lambda-s3-media-policy"
  description = "Cho phep Lambda doc anh tu uploads/, ghi anh WebP vao processed/ va thumbnails/, chuyen Glacier IR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:GetObjectTagging",
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
          "s3:PutObjectAcl",
          "s3:PutObjectTagging",
          "s3:DeleteObject"
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
# 2. S3 CORS CONFIGURATION CHO TRÌNH DUYỆT UPLOAD TRỰC TIẾP QUA PRESIGNED URL
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_cors_configuration" "assets_cors" {
  bucket = var.s3_static_assets_bucket_name

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "HEAD"]
    allowed_origins = [
      "https://cloudmedia.duccloud.men",
      "https://d10b9bys5mn60c.cloudfront.net",
      "http://localhost:3000",
      "http://localhost:8080",
      "http://127.0.0.1:3000"
    ]
    expose_headers  = ["ETag", "x-amz-request-id"]
    max_age_seconds = 3600
  }
}

# ------------------------------------------------------------------------------
# 3. HÀM LAMBDA 1: REAL WEBP & THUMBNAIL PROCESSOR (SHARP ON ARM64 GRAVITON2)
# ------------------------------------------------------------------------------
resource "aws_lambda_function" "image_processor" {
  function_name    = "${var.project_name}-image-processor"
  description      = "Cloud Media Studio Real WebP compression & 3-size thumbnail generator (sharp ARM64)"
  filename         = "${path.module}/lambda_payload.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_payload.zip")
  role             = aws_iam_role.lambda_image_processor.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  architectures    = ["arm64"]
  memory_size      = 512
  timeout          = 30

  environment {
    variables = {
      DESTINATION_BUCKET       = "${var.project_name}-processed-${var.aws_region}"
      AUTO_GENERATE_THUMBNAILS = "true"
      TARGET_FORMAT            = "WEBP"
      ENVIRONMENT              = var.environment
      LD_LIBRARY_PATH          = "/var/task/node_modules/@img/sharp-libvips-linux-arm64/lib:/var/lang/lib:/lib64:/usr/lib64"
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
    id                  = "cms-s3-uploads-webp-trigger"
    lambda_function_arn = aws_lambda_function.image_processor.arn
    events = [
      "s3:ObjectCreated:Put",
      "s3:ObjectCreated:Post",
      "s3:ObjectCreated:CompleteMultipartUpload"
    ]
    filter_prefix = "uploads/"
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}

# ------------------------------------------------------------------------------
# 4. HÀM LAMBDA 2: SERVERLESS MEDIA & PRESIGNED URL API (FUNCTION URL HTTPS)
# ------------------------------------------------------------------------------
resource "aws_lambda_function" "media_api" {
  function_name    = "${var.project_name}-api"
  description      = "Cloud Media Studio Serverless Presigned S3 & Live Media API"
  filename         = "${path.module}/lambda_api_payload.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_api_payload.zip")
  role             = aws_iam_role.lambda_image_processor.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  architectures    = ["arm64"]
  memory_size      = 256
  timeout          = 20

  environment {
    variables = {
      ASSETS_BUCKET = var.s3_static_assets_bucket_name
      CDN_DOMAIN    = "https://cloudmedia.duccloud.men"
      ENVIRONMENT   = var.environment
    }
  }

  tags = {
    Name        = "${var.project_name}-api"
    Role        = "Serverless-API-Gateway"
    Owner       = "Member2-Compute"
    Environment = var.environment
  }
}

resource "aws_lambda_function_url" "media_api_url" {
  function_name      = aws_lambda_function.media_api.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "allow_public_function_url" {
  statement_id           = "AllowPublicFunctionUrl"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.media_api.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

# ------------------------------------------------------------------------------
# 5. OUTPUTS CHO THÀNH VIÊN 2 & HỘI ĐỒNG XEM XÉT
# ------------------------------------------------------------------------------
output "lambda_image_processor_arn" {
  description = "ARN cua ham AWS Lambda xu ly media tu dong"
  value       = aws_lambda_function.image_processor.arn
}

output "lambda_image_processor_name" {
  description = "Ten cua ham AWS Lambda xu ly media tu dong"
  value       = aws_lambda_function.image_processor.function_name
}

output "lambda_media_api_url" {
  description = "HTTPS Endpoint cong khai cua Serverless Media & Presigned S3 API"
  value       = aws_lambda_function_url.media_api_url.function_url
}
