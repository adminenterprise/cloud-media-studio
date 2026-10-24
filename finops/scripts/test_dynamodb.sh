#!/usr/bin/env bash
# ==============================================================================
# ENTERPRISE CLOUD DEVSECOPS — KIỂM THỬ DỮ LIỆU TUẦN 3 (FINOPS)
# ==============================================================================
# Phân mảng: Thành viên 3 (Dữ liệu & FinOps — Phạm Thế Hùng)
# Tự động kiểm tra trạng thái DynamoDB, CRUD User Session & Cart, xác thực S3 Glacier

set -e

REGION="${1:-ap-southeast-1}"
PROJECT_NAME="${2:-enterprise-cloud-devsecops}"
ACTION="${3:-all}"

SESSION_TABLE="${PROJECT_NAME}-user-sessions"
CART_TABLE="${PROJECT_NAME}-cart"
S3_BUCKET="${PROJECT_NAME}-static-assets-${REGION}"

echo "======================================================================"
echo "  ENTERPRISE CLOUD DEVSECOPS — KIỂM THỬ DỮ LIỆU TUẦN 3 (BASH)         "
echo "======================================================================"
echo "Region       : $REGION"
echo "Project Name : $PROJECT_NAME"
echo "Action       : $ACTION"
echo ""

check_table() {
    local table_name="$1"
    echo "[+] Kiểm tra bảng DynamoDB: $table_name..."
    local status
    status=$(aws dynamodb describe-table --table-name "$table_name" --region "$REGION" --query "Table.TableStatus" --output text 2>/dev/null || echo "NOT_FOUND")
    if [ "$status" != "NOT_FOUND" ]; then
        echo "    Trạng thái : $status"
        local ttl
        ttl=$(aws dynamodb describe-time-to-live --table-name "$table_name" --region "$REGION" --query "TimeToLiveDescription.TimeToLiveStatus" --output text 2>/dev/null || echo "DISABLED")
        echo "    TTL Status : $ttl (expiresAt)"
    else
        echo "    [!] Không tìm thấy bảng $table_name"
    fi
}

test_crud() {
    echo ""
    echo "--- [1] KIỂM THỬ USER SESSIONS TABLE ---"
    local sess_id="sess_bash_$(date +%s)"
    local now_epoch
    now_epoch=$(date +%s)
    local expire_epoch=$((now_epoch + 604800))

    echo "  -> Ghi User Session mới ($sess_id)..."
    aws dynamodb put-item --table-name "$SESSION_TABLE" --region "$REGION" --item "{
        \"sessionId\": {\"S\": \"$sess_id\"},
        \"userId\": {\"S\": \"user_bash_demo\"},
        \"createdAt\": {\"N\": \"$now_epoch\"},
        \"expiresAt\": {\"N\": \"$expire_epoch\"},
        \"role\": {\"S\": \"Member3-Data-FinOps\"}
    }"
    echo "     [OK] Đã ghi thành công User Session!"

    echo "  -> Đọc User Session..."
    aws dynamodb get-item --table-name "$SESSION_TABLE" --region "$REGION" \
        --key "{\"sessionId\": {\"S\": \"$sess_id\"}}" --output json
    echo "     [OK] Đọc session thành công!"

    echo ""
    echo "--- [2] KIỂM THỬ SHOPPING CART TABLE ---"
    local item_id="item_aws_cloud_course_99"
    echo "  -> Thêm sản phẩm vào giỏ hàng..."
    aws dynamodb put-item --table-name "$CART_TABLE" --region "$REGION" --item "{
        \"userId\": {\"S\": \"user_bash_demo\"},
        \"itemId\": {\"S\": \"$item_id\"},
        \"title\": {\"S\": \"AWS FinOps Architect\"},
        \"quantity\": {\"N\": \"1\"},
        \"unitPrice\": {\"N\": \"79.99\"},
        \"expiresAt\": {\"N\": \"$expire_epoch\"}
    }"
    echo "     [OK] Thêm vào giỏ hàng thành công!"

    echo "  -> Đọc giỏ hàng..."
    aws dynamodb get-item --table-name "$CART_TABLE" --region "$REGION" \
        --key "{\"userId\": {\"S\": \"user_bash_demo\"}, \"itemId\": {\"S\": \"$item_id\"}}" --output json
    echo "     [OK] Đọc giỏ hàng thành công!"
}

check_s3() {
    echo ""
    echo "--- [3] KIỂM TRA S3 GLACIER LIFECYCLE (FINOPS) ---"
    echo "Bucket: $S3_BUCKET"
    aws s3api get-bucket-lifecycle-configuration --bucket "$S3_BUCKET" --region "$REGION" --output json || echo "    [!] Chưa có Lifecycle Configuration"
}

case "$ACTION" in
    status)
        check_table "$SESSION_TABLE"
        check_table "$CART_TABLE"
        check_s3
        ;;
    crud)
        test_crud
        ;;
    s3)
        check_s3
        ;;
    all)
        check_table "$SESSION_TABLE"
        check_table "$CART_TABLE"
        test_crud
        check_s3
        ;;
    *)
        echo "Hành động hợp lệ: status | crud | s3 | all"
        ;;
esac

echo ""
echo "======================================================================"
echo "  HOÀN TẤT KIỂM THỬ TUẦN 3 (MEMBER 3)!                                "
echo "======================================================================"
