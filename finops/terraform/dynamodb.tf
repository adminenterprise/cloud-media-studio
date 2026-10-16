# ==============================================================================
# AMAZON DYNAMODB (NOSQL) — TUẦN 3: USER SESSIONS & SHOPPING CART
# ==============================================================================
# Phân mảng: Thành viên 3 (Dữ liệu & FinOps — Phạm Thế Hùng)
# Mục đích: Lưu trữ dữ liệu phi quan hệ, độ trễ thấp (single-digit millisecond)
# - User Sessions: Lưu phiên đăng nhập người dùng, token, thông tin thiết bị
# - Shopping Cart: Lưu giỏ hàng tạm thời, sản phẩm đang chọn
# FinOps: Chế độ PAY_PER_REQUEST (On-Demand) hoặc Free Tier (dưới 25 GB, 25 WCU, 25 RCU)
# Tự động hóa dọn rác: Cấu hình Time-To-Live (TTL) tự động xóa bản ghi hết hạn MIỄN PHÍ

# ------------------------------------------------------------------------------
# 1. BẢNG DYNAMODB: USER SESSIONS (PHIÊN LÀM VIỆC NGƯỜI DÙNG)
# ------------------------------------------------------------------------------
resource "aws_dynamodb_table" "user_sessions" {
  name         = "${var.project_name}-user-sessions"
  billing_mode = var.dynamodb_billing_mode
  hash_key     = "sessionId"

  # Khóa chính (Partition Key)
  attribute {
    name = "sessionId"
    type = "S"
  }

  # Thuộc tính hỗ trợ Global Secondary Index (GSI)
  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "N"
  }

  # Global Secondary Index: Cho phép truy vấn nhanh tất cả session theo userId
  global_secondary_index {
    name            = "userId-createdAt-index"
    hash_key        = "userId"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  # Time-To-Live (TTL): DynamoDB tự quét và xóa session quá hạn không tốn WCU
  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  # Mã hóa Server-Side Encryption mặc định của AWS (Miễn phí)
  server_side_encryption {
    enabled = true
  }

  # Khôi phục dữ liệu theo thời gian (PITR)
  point_in_time_recovery {
    enabled = var.dynamodb_enable_pitr
  }

  tags = {
    Name         = "${var.project_name}-user-sessions"
    Tier         = "Database"
    DatabaseType = "NoSQL-DynamoDB"
    Week         = "Week-3"
    CostCenter   = "Member3-Data-FinOps"
    Purpose      = "UserSessionStore"
  }
}

# ------------------------------------------------------------------------------
# 2. BẢNG DYNAMODB: SHOPPING CART (GIỎ HÀNG TẠM THỜI)
# ------------------------------------------------------------------------------
resource "aws_dynamodb_table" "cart" {
  name         = "${var.project_name}-cart"
  billing_mode = var.dynamodb_billing_mode
  hash_key     = "userId"
  range_key    = "itemId"

  # Khóa phân vùng (Partition Key): Mã người dùng
  attribute {
    name = "userId"
    type = "S"
  }

  # Khóa sắp xếp (Sort Key): Mã sản phẩm trong giỏ
  attribute {
    name = "itemId"
    type = "S"
  }

  # Time-To-Live (TTL): Tự động dọn giỏ hàng sau 14 hoặc 30 ngày không thanh toán
  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  # Mã hóa SSE
  server_side_encryption {
    enabled = true
  }

  # Khôi phục theo thời gian (PITR)
  point_in_time_recovery {
    enabled = var.dynamodb_enable_pitr
  }

  tags = {
    Name         = "${var.project_name}-cart"
    Tier         = "Database"
    DatabaseType = "NoSQL-DynamoDB"
    Week         = "Week-3"
    CostCenter   = "Member3-Data-FinOps"
    Purpose      = "ShoppingCartStore"
  }
}
