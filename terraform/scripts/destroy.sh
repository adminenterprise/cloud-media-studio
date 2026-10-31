#!/usr/bin/env bash
# ==============================================================================
# SCRIPT THU HỒI HẠ TẦNG AN TOÀN (BASH / LINUX / MACOS / WSL)
# Dự án: ENTERPRISE CLOUD & DEVSECOPS PLATFORM
# Vai trò: Thành viên 1 (Nhóm trưởng — Mạng & IaC)
# Tuần 6: Tối ưu hóa & Quản trị tài chính (FinOps)
# ==============================================================================

set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")"

FORCE=false
for arg in "$@"; do
  case $arg in
    -f|--force)
      FORCE=true
      shift
      ;;
  esac
done

echo -e "${RED}==============================================================${NC}"
echo -e "${RED}  ENTERPRISE CLOUD & DEVSECOPS PLATFORM — DESTROY INFRASTRUCTURE${NC}"
echo -e "${RED}  Role: Member 1 (FinOps Clean-Up Protocol)                    ${NC}"
echo -e "${RED}==============================================================${NC}\n"

cd "$TERRAFORM_DIR"

echo -e "${YELLOW}CẢNH BÁO QUAN TRỌNG:${NC}"
echo -e "${YELLOW}- Lệnh này sẽ XÓA TOÀN BỘ tài nguyên mạng đã tạo (VPCs, Subnets, Gateways, SGs, ALB, WAF, Peering).${NC}"
echo -e "${YELLOW}- Thao tác này nhằm bảo vệ số dư tài khoản $200 sau các buổi demo/diễn tập.${NC}\n"

if [ "$FORCE" = false ]; then
  read -p "Để xác nhận, vui lòng nhập chính xác cụm từ DESTROY (hoặc ấn Ctrl+C để hủy): " confirmation
  if [ "$confirmation" != "DESTROY" ]; then
    echo -e "${GREEN}Thao tác hủy tài nguyên đã bị hủy bỏ. Không có thay đổi nào xảy ra.${NC}"
    exit 0
  fi
fi

echo -e "${CYAN}Đang thực thi 'terraform destroy'...${NC}"
terraform destroy -auto-approve

echo -e "\n${GREEN}==============================================================${NC}"
echo -e "${GREEN}  ĐÃ THU HỒI TOÀN BỘ HẠ TẦNG THÀNH CÔNG!                      ${NC}"
echo -e "${GREEN}  Trạng thái: An toàn cho ngân sách FinOps ($200 Credit).     ${NC}"
echo -e "${GREEN}==============================================================${NC}"

