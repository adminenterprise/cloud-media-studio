#!/usr/bin/env bash
# ==============================================================================
# SCRIPT TRIỂN KHAI HẠ TẦNG 1-CLICK (BASH / LINUX / MACOS / WSL)
# Dự án: ENTERPRISE CLOUD & DEVSECOPS PLATFORM
# Vai trò: Thành viên 1 (Nhóm trưởng — Mạng & IaC)
# Tuần 6: Tối ưu hóa & Tự động hóa hạ tầng
# ==============================================================================

set -e

# Màu sắc hiển thị terminal
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")"

AUTO_APPROVE=false
SKIP_AUTH=false

for arg in "$@"; do
  case $arg in
    -y|--auto-approve)
      AUTO_APPROVE=true
      shift
      ;;
    --skip-auth)
      SKIP_AUTH=true
      shift
      ;;
  esac
done

echo -e "${CYAN}==============================================================${NC}"
echo -e "${CYAN}  ENTERPRISE CLOUD & DEVSECOPS PLATFORM — 1-CLICK DEPLOYMENT  ${NC}"
echo -e "${CYAN}  Role: Member 1 (Network & Infrastructure as Code)            ${NC}"
echo -e "${CYAN}==============================================================${NC}\n"

# 1. Chuyển vào thư mục terraform
cd "$TERRAFORM_DIR"
echo -e "${GREEN}[1/6] Thư mục làm việc: $TERRAFORM_DIR${NC}"

# 2. Kiểm tra thông tin xác thực AWS CLI
if [ "$SKIP_AUTH" = false ]; then
  echo -e "${YELLOW}[2/6] Kiểm tra quyền truy cập AWS CLI...${NC}"
  if aws sts get-caller-identity > /dev/null 2>&1; then
    ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
    USER_ARN=$(aws sts get-caller-identity --query "Arn" --output text)
    echo -e "       AWS Account : $ACCOUNT_ID"
    echo -e "       ARN Identity: $USER_ARN"
    echo -e "${GREEN}       Xác thực AWS thành công!${NC}"
  else
    echo -e "${RED}CẢNH BÁO: Không thể kết nối AWS CLI! Hãy đảm bảo đã cấu hình 'aws configure' hoặc biến môi trường.${NC}"
    read -p "Bạn có muốn tiếp tục chạy chế độ kiểm tra cục bộ (validate) không? (y/n) " choice
    if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
      exit 1
    fi
  fi
else
  echo -e "${YELLOW}[2/6] Bỏ qua kiểm tra AWS CLI (--skip-auth).${NC}"
fi

# 3. Kiểm tra file cấu hình terraform.tfvars
echo -e "${YELLOW}[3/6] Kiểm tra biến cấu hình (terraform.tfvars)...${NC}"
if [ ! -f "terraform.tfvars" ]; then
  if [ -f "terraform.tfvars.example" ]; then
    echo -e "${CYAN}       Chưa có terraform.tfvars. Đang tự động sao chép từ terraform.tfvars.example...${NC}"
    cp terraform.tfvars.example terraform.tfvars
    echo -e "${GREEN}       Đã tạo terraform.tfvars mặc định.${NC}"
  else
    echo -e "${RED}CẢNH BÁO: Không tìm thấy terraform.tfvars hay terraform.tfvars.example!${NC}"
  fi
else
  echo -e "${GREEN}       File terraform.tfvars đã sẵn sàng.${NC}"
fi

# 4. Khởi tạo & Kiểm tra tính hợp lệ của Terraform
echo -e "${YELLOW}[4/6] Khởi tạo & Kiểm tra tính toàn vẹn (Init & Validate)...${NC}"
terraform init -no-color

if ! terraform fmt -check > /dev/null 2>&1; then
  echo -e "${CYAN}       Cảnh báo định dạng. Đang tự động format lại bằng 'terraform fmt'...${NC}"
  terraform fmt
fi

terraform validate
echo -e "${GREEN}       Mã nguồn Terraform hoàn toàn hợp lệ!${NC}"

# 5. Tạo kế hoạch triển khai (Plan)
echo -e "${YELLOW}[5/6] Lập kế hoạch triển khai (Terraform Plan)...${NC}"
echo -e "${MAGENTA}       LƯU Ý FINOPS: NAT Gateway (~$0.045/giờ) và ALB (~$0.0225/giờ) sẽ tiêu hao từ gói $200.${NC}"
terraform plan -out=tfplan

# 6. Xác nhận và Triển khai (Apply)
echo -e "\n${YELLOW}[6/6] Sẵn sàng triển khai hạ tầng lên AWS!${NC}"
if [ "$AUTO_APPROVE" = false ]; then
  read -p "Bạn có chắc chắn muốn triển khai kế hoạch trên lên AWS không? (nhập 'yes' để xác nhận): " confirm
  if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}Đã hủy bỏ lệnh triển khai. Kế hoạch tạm thời 'tfplan' đã được xóa.${NC}"
    rm -f tfplan
    exit 0
  fi
fi

echo -e "${CYAN}Đang thực thi 'terraform apply'...${NC}"
terraform apply -auto-approve tfplan
rm -f tfplan

echo -e "\n${GREEN}==============================================================${NC}"
echo -e "${GREEN}  TRIỂN KHAI HẠ TẦNG THÀNH CÔNG (1-CLICK DEPLOY COMPLETE)     ${NC}"
echo -e "${GREEN}==============================================================${NC}\n"

echo -e "${CYAN}--- BẢNG THÔNG SỐ BÀN GIAO CHO CÁC THÀNH VIÊN (OUTPUTS) ---${NC}"
terraform output

echo -e "\n${YELLOW}GHI NHỚ FINOPS: Sau khi kiểm thử hoặc diễn tập xong, hãy chạy './scripts/destroy.sh' để hủy tài nguyên nhằm tiết kiệm ngân sách $200.${NC}"

