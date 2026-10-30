#!/bin/bash
# ==============================================================================
# IAM LEAST PRIVILEGE AUTOMATION SCRIPT - TUẦN 1 (BASH)
# Phân mảng: Thành viên 3 (Dữ liệu & FinOps)
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/configs"

echo "=========================================================="
echo "  IAM LEAST PRIVILEGE AUTOMATION SCRIPT"
echo "=========================================================="

echo "[1/4] Cập nhật chính sách mật khẩu mạnh..."
aws iam update-account-password-policy \
    --minimum-password-length 12 \
    --require-symbols \
    --require-numbers \
    --require-uppercase-characters \
    --require-lowercase-characters \
    --allow-users-to-change-password \
    --max-password-age 90 \
    --password-reuse-prevention 3

echo "[2/4] Tạo Base Policy chung..."
BASE_POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='EnterpriseCloud-CommonBase-Policy'].Arn" --output text 2>/dev/null)
if [ -z "$BASE_POLICY_ARN" ]; then
    BASE_POLICY_ARN=$(aws iam create-policy --policy-name "EnterpriseCloud-CommonBase-Policy" --policy-document file://"$CONFIG_DIR/policy_common_base.json" --query "Policy.Arn" --output text)
fi

ROLES=(
    "Network-IaC-Group:member1-network-iac:EnterpriseCloud-Member1-NetworkIaC-Policy:policy_member1_network.json"
    "Compute-Container-Group:member2-compute-container:EnterpriseCloud-Member2-ComputeContainer-Policy:policy_member2_compute.json"
    "Data-FinOps-Group:member3-data-finops:EnterpriseCloud-Member3-DataFinOps-Policy:policy_member3_data.json"
    "Security-DevSecOps-Group:member4-security-devsecops:EnterpriseCloud-Member4-SecurityDevSecOps-Policy:policy_member4_security.json"
)

echo "[3/4] Khởi tạo các nhóm và tài khoản chuyên mảng..."
for entry in "${ROLES[@]}"; do
    IFS=":" read -r GRP USR POL_NAME POL_FILE <<< "$entry"
    echo "  -> Đang xử lý $GRP ($USR)..."

    aws iam create-group --group-name "$GRP" 2>/dev/null || true
    aws iam attach-group-policy --group-name "$GRP" --policy-arn "$BASE_POLICY_ARN" 2>/dev/null || true

    SPEC_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='$POL_NAME'].Arn" --output text 2>/dev/null)
    if [ -z "$SPEC_ARN" ]; then
        SPEC_ARN=$(aws iam create-policy --policy-name "$POL_NAME" --policy-document file://"$CONFIG_DIR/$POL_FILE" --query "Policy.Arn" --output text)
    fi
    aws iam attach-group-policy --group-name "$GRP" --policy-arn "$SPEC_ARN" 2>/dev/null || true

    aws iam create-user --user-name "$USR" 2>/dev/null || true
    aws iam add-user-to-group --user-name "$USR" --group-name "$GRP" 2>/dev/null || true
done

echo ""
echo "[4/4] >>> THÀNH CÔNG: Hoàn tất khởi tạo 4 IAM Users & Groups!"
