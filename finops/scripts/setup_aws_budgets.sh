#!/bin/bash
# ==============================================================================
# AWS BUDGETS FINOPS AUTOMATION SCRIPT - TUẦN 1 (BASH)
# Phân mảng: Thành viên 3 (Dữ liệu & FinOps)
# ==============================================================================

set -e

EMAIL=${1:-"minhquan10092006@gmail.com"}
ACCOUNT_ID=${2:-$(aws sts get-caller-identity --query "Account" --output text 2>/dev/null)}

echo "=========================================================="
echo "  AWS BUDGETS FINOPS AUTOMATION SCRIPT"
echo "=========================================================="

if [ -z "$ACCOUNT_ID" ]; then
    echo "Lỗi: Không tìm thấy AWS Account ID. Vui lòng cấu hình AWS CLI trước (aws configure) hoặc truyền Account ID làm đối số thứ 2."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/configs/budget_payload.json"
TEMP_FILE="$SCRIPT_DIR/configs/budget_temp.json"

echo "[1/3] AWS Account ID: $ACCOUNT_ID"
echo "[2/3] Email nhận cảnh báo: $EMAIL"

sed "s/admin-cloud@example.com/$EMAIL/g" "$CONFIG_FILE" > "$TEMP_FILE"

BUDGET_JSON=$(jq -c '.Budget' "$TEMP_FILE")
NOTIF_JSON=$(jq -c '.NotificationsWithSubscribers' "$TEMP_FILE")

echo "[3/3] Đang gọi AWS Budgets API khởi tạo ngân sách..."
aws budgets create-budget \
    --account-id "$ACCOUNT_ID" \
    --budget "$BUDGET_JSON" \
    --notifications-with-subscribers "$NOTIF_JSON"

rm -f "$TEMP_FILE"

echo ""
echo ">>> THÀNH CÔNG: Đã khởi tạo AWS Budget thành công!"
echo "    - Hạn mức: $200 USD"
echo "    - Cảnh báo: $20 (10%) và $50 (25%) gửi về $EMAIL"
