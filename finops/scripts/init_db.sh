#!/bin/bash
# ==============================================================================
# SCRIPT KHỞI TẠO CƠ SỞ DỮ LIỆU RDS MYSQL (MEMBER 3 -> MEMBER 2)
# ==============================================================================
# Mục đích: Nạp schema và dữ liệu mẫu từ db/init.sql vào RDS MySQL
#
# Cách dùng:
#   ./init_db.sh <rds-host> <admin-password> [admin-user] [database-name] [port] [sql-file]
#
# Ví dụ:
#   ./init_db.sh enterprise-cloud-devsecops-mysql-primary.xxxx.ap-southeast-1.rds.amazonaws.com MyPass123
# ==============================================================================

set -e

HOST="${1:-}"
PASSWORD="${2:-}"
USER="${3:-admin}"
DB_NAME="${4:-appdb}"
PORT="${5:-3306}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_FILE="${6:-$SCRIPT_DIR/../../db/init.sql}"

if [ -z "$HOST" ] || [ -z "$PASSWORD" ]; then
  echo "Usage: $0 <rds-host> <admin-password> [admin-user] [database-name] [port] [sql-file]"
  echo ""
  echo "Example:"
  echo "  $0 enterprise-cloud-devsecops-mysql-primary.xxxx.ap-southeast-1.rds.amazonaws.com MySecretPass123"
  exit 1
fi

# Tách port nếu host có dạng endpoint:3306
CLEAN_HOST=$(echo "$HOST" | cut -d: -f1)

echo ""
echo "========================================"
echo "  RDS DATABASE INITIALIZER - Member 3"
echo "========================================"
echo "  Host     : $CLEAN_HOST"
echo "  Port     : $PORT"
echo "  Database : $DB_NAME"
echo "  User     : $USER"
echo "  SQL File : $SQL_FILE"
echo "========================================"
echo ""

if [ ! -f "$SQL_FILE" ]; then
  echo "[ERROR] File SQL khong ton tai: $SQL_FILE"
  exit 1
fi

if ! command -v mysql &> /dev/null; then
  echo "[WARNING] Lenh 'mysql' chua duoc cai dat tren may nay."
  echo "[TIP] Tren Amazon Linux 2023 / Bastion Host, chay:"
  echo "      sudo dnf install -y mariadb105"
  echo ""
  echo "[TIP] Hoac chay qua Docker:"
  echo "      docker run --rm -v \"$SQL_FILE\":/init.sql mysql:8.0 mysql -h \"$CLEAN_HOST\" -P \"$PORT\" -u \"$USER\" -p\"$PASSWORD\" \"$DB_NAME\" < /init.sql"
  exit 1
fi

echo "[INFO] Dang nap du lieu vao RDS MySQL..."
export MYSQL_PWD="$PASSWORD"
mysql -h "$CLEAN_HOST" -P "$PORT" -u "$USER" "$DB_NAME" < "$SQL_FILE"
unset MYSQL_PWD

echo ""
echo "[OK] Khoi tao database $DB_NAME thanh cong!"
echo "[OK] Da nap cac ban ghi mau tu db/init.sql."
echo "[OK] San sang ban giao cho Member 2 (Backend NodeJS)!"
echo ""
