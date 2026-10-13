#!/bin/bash
# ==============================================================================
# FINOPS UTILITY: STOP / START / STATUS RDS MYSQL INSTANCE
# ==============================================================================
# Mục đích: Tiết kiệm credit $200 bằng cách stop RDS khi không sử dụng
# Chi phí tiết kiệm: ~$0.018/giờ (~$0.43/ngày)
#
# Cách dùng:
#   ./stop_rds.sh stop      # Tắt RDS (tiết kiệm credit)
#   ./stop_rds.sh start     # Bật RDS (khi cần test)
#   ./stop_rds.sh status    # Kiểm tra trạng thái hiện tại
# ==============================================================================

INSTANCE_ID="${2:-enterprise-cloud-devsecops-mysql-primary}"
REGION="${3:-ap-southeast-1}"

echo ""
echo "========================================"
echo "  FINOPS RDS MANAGER - Member 3"
echo "========================================"
echo "  Instance : $INSTANCE_ID"
echo "  Region   : $REGION"
echo "  Action   : $1"
echo "========================================"
echo ""

case "$1" in
  stop)
    echo "[FinOps] Dang stop RDS instance: $INSTANCE_ID ..."
    echo "[FinOps] Luu y: RDS se tu dong bat lai sau 7 ngay!"
    echo ""

    if aws rds stop-db-instance \
        --db-instance-identifier "$INSTANCE_ID" \
        --region "$REGION" \
        --output json > /dev/null 2>&1; then
      echo "[OK] RDS da duoc gui lenh STOP thanh cong!"
      echo "[OK] Tiet kiem ~\$0.018/gio (~\$0.43/ngay)"
      echo "[OK] Trang thai se chuyen sang 'stopping' -> 'stopped' sau 1-2 phut."
    else
      echo "[ERROR] Khong the stop RDS. Kiem tra lai Instance ID va quyen IAM."
    fi
    ;;

  start)
    echo "[FinOps] Dang start RDS instance: $INSTANCE_ID ..."
    echo ""

    if aws rds start-db-instance \
        --db-instance-identifier "$INSTANCE_ID" \
        --region "$REGION" \
        --output json > /dev/null 2>&1; then
      echo "[OK] RDS dang khoi dong lai!"
      echo "[OK] Vui long cho 3-5 phut de instance san sang (Available)."
      echo "[OK] Chay './stop_rds.sh status' de kiem tra."
    else
      echo "[ERROR] Khong the start RDS. Kiem tra lai Instance ID va quyen IAM."
    fi
    ;;

  status)
    echo "[FinOps] Dang kiem tra trang thai RDS..."
    echo ""

    aws rds describe-db-instances \
      --db-instance-identifier "$INSTANCE_ID" \
      --region "$REGION" \
      --query "DBInstances[0].{Status:DBInstanceStatus,Endpoint:Endpoint.Address,Port:Endpoint.Port,AZ:AvailabilityZone,Class:DBInstanceClass,MultiAZ:MultiAZ,Storage:AllocatedStorage,Engine:Engine,EngineVersion:EngineVersion}" \
      --output table

    echo ""

    STATUS=$(aws rds describe-db-instances \
      --db-instance-identifier "$INSTANCE_ID" \
      --region "$REGION" \
      --query "DBInstances[0].DBInstanceStatus" \
      --output text 2>/dev/null)

    if [ "$STATUS" = "available" ]; then
      echo "[TIP] RDS dang chay. Neu khong can, hay chay: ./stop_rds.sh stop"
    elif [ "$STATUS" = "stopped" ]; then
      echo "[TIP] RDS da tat. Khi can test, chay: ./stop_rds.sh start"
    else
      echo "[INFO] RDS dang o trang thai: $STATUS. Vui long cho..."
    fi
    ;;

  *)
    echo "Cach su dung:"
    echo "  $0 stop   [instance-id] [region]   # Tat RDS (tiet kiem credit)"
    echo "  $0 start  [instance-id] [region]   # Bat RDS (khi can test)"
    echo "  $0 status [instance-id] [region]   # Kiem tra trang thai"
    echo ""
    echo "Mac dinh:"
    echo "  Instance ID : enterprise-cloud-devsecops-mysql-primary"
    echo "  Region      : ap-southeast-1"
    exit 1
    ;;
esac

echo ""
