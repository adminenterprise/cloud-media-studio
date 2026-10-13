# ==============================================================================
# SCRIPT KHỞI TẠO CƠ SỞ DỮ LIỆU RDS MYSQL (MEMBER 3 -> MEMBER 2)
# ==============================================================================
# Mục đích: Nạp lược đồ (schema) và dữ liệu mẫu từ db/init.sql vào RDS MySQL
# để Member 2 (Backend NodeJS) có thể kết nối và chạy kiểm thử ngay lập tức.
#
# Cách dùng:
#   .\init_db.ps1 -Host "terraform-output-rds-endpoint" -Password "YourPassword"
#   .\init_db.ps1 -Host "10.0.20.15" -User "admin" -Password "pass" -DbName "appdb"
# ==============================================================================

param(
    [Parameter(Mandatory = $true)]
    [string]$Host,

    [string]$User = "admin",

    [Parameter(Mandatory = $true)]
    [string]$Password,

    [string]$DbName = "appdb",
    [int]$Port = 3306,
    [string]$SqlFile = ""
)

$ErrorActionPreference = "Stop"

# Xác định đường dẫn file SQL mặc định (../../db/init.sql)
if (-not $SqlFile) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $SqlFile = Join-Path (Split-Path -Parent $scriptDir) "..\db\init.sql"
    $SqlFile = [System.IO.Path]::GetFullPath($SqlFile)
}

Write-Host ""
Write-Host "========================================" -ForegroundColor DarkCyan
Write-Host "  RDS DATABASE INITIALIZER - Member 3" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor DarkCyan
Write-Host "  Host     : $Host" -ForegroundColor Gray
Write-Host "  Port     : $Port" -ForegroundColor Gray
Write-Host "  Database : $DbName" -ForegroundColor Gray
Write-Host "  User     : $User" -ForegroundColor Gray
Write-Host "  SQL File : $SqlFile" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor DarkCyan
Write-Host ""

if (-not (Test-Path $SqlFile)) {
    Write-Host "[ERROR] Khong tim thay file SQL: $SqlFile" -ForegroundColor Red
    exit 1
}

# Lọc bỏ port nếu Host có dạng "endpoint:3306"
$cleanHost = $Host.Split(":")[0]

Write-Host "[INFO] Dang kiem tra mysql CLI client..." -ForegroundColor Yellow
$mysqlCmd = Get-Command mysql -ErrorAction SilentlyContinue

if ($null -eq $mysqlCmd) {
    Write-Host "[WARNING] May tinh chua cai dat MySQL CLI client ('mysql')." -ForegroundColor Yellow
    Write-Host "[TIP] Neu ban dang chay tu Bastion Host (EC2), hay chay lenh sau truoc:" -ForegroundColor Cyan
    Write-Host "      sudo dnf install -y mariadb105" -ForegroundColor White
    Write-Host ""
    Write-Host "[TIP] Hoac chay container Docker tam thoi de nap du lieu:" -ForegroundColor Cyan
    Write-Host "      docker run --rm -v ${SqlFile}:/init.sql mysql:8.0 mysql -h $cleanHost -P $Port -u $User -p'$Password' $DbName < /init.sql" -ForegroundColor White
    exit 1
}

Write-Host "[INFO] Dang nap schema va du lieu vao RDS MySQL..." -ForegroundColor Cyan

try {
    $env:MYSQL_PWD = $Password
    & mysql -h $cleanHost -P $Port -u $User $DbName -e "source $SqlFile"
    $env:MYSQL_PWD = $null

    Write-Host ""
    Write-Host "[OK] Khoi tao database $DbName thanh cong!" -ForegroundColor Green
    Write-Host "[OK] Da nap cac ban ghi mau tu db/init.sql." -ForegroundColor Green
    Write-Host "[OK] San sang ban giao cho Member 2 (Backend NodeJS)!" -ForegroundColor DarkGreen
}
catch {
    $env:MYSQL_PWD = $null
    Write-Host ""
    Write-Host "[ERROR] Nap database that bai: $_" -ForegroundColor Red
    Write-Host "[TIP] Dam bao Security Group cho phep port 3306 va may ban co route toi Private DB Subnet." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
