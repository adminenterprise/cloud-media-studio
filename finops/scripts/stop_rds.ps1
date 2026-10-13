# ==============================================================================
# FINOPS UTILITY: STOP / START / STATUS RDS MYSQL INSTANCE
# ==============================================================================
# Mục đích: Tiết kiệm credit $200 bằng cách stop RDS khi không sử dụng
# Chi phí tiết kiệm: ~$0.018/giờ (~$0.43/ngày)
#
# Cách dùng:
#   .\stop_rds.ps1 -Action stop      # Tắt RDS (tiết kiệm credit)
#   .\stop_rds.ps1 -Action start     # Bật RDS (khi cần test)
#   .\stop_rds.ps1 -Action status    # Kiểm tra trạng thái hiện tại
# ==============================================================================

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("stop", "start", "status")]
    [string]$Action,

    [string]$InstanceId = "enterprise-cloud-devsecops-mysql-primary",
    [string]$Region = "ap-southeast-1"
)

Write-Host ""
Write-Host "========================================" -ForegroundColor DarkCyan
Write-Host "  FINOPS RDS MANAGER - Member 3" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor DarkCyan
Write-Host "  Instance : $InstanceId" -ForegroundColor Gray
Write-Host "  Region   : $Region" -ForegroundColor Gray
Write-Host "  Action   : $Action" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor DarkCyan
Write-Host ""

switch ($Action) {
    "stop" {
        Write-Host "[FinOps] Dang stop RDS instance..." -ForegroundColor Yellow
        Write-Host "[FinOps] Luu y: RDS se tu dong bat lai sau 7 ngay!" -ForegroundColor DarkYellow
        Write-Host ""

        try {
            aws rds stop-db-instance `
                --db-instance-identifier $InstanceId `
                --region $Region `
                --output json 2>&1 | Out-Null

            Write-Host "[OK] RDS da duoc gui lenh STOP thanh cong!" -ForegroundColor Green
            Write-Host "[OK] Tiet kiem ~`$0.018/gio (~`$0.43/ngay)" -ForegroundColor Green
            Write-Host "[OK] Trang thai se chuyen sang 'stopping' -> 'stopped' sau 1-2 phut." -ForegroundColor DarkGreen
        }
        catch {
            Write-Host "[ERROR] Khong the stop RDS: $_" -ForegroundColor Red
        }
    }

    "start" {
        Write-Host "[FinOps] Dang start RDS instance..." -ForegroundColor Cyan
        Write-Host ""

        try {
            aws rds start-db-instance `
                --db-instance-identifier $InstanceId `
                --region $Region `
                --output json 2>&1 | Out-Null

            Write-Host "[OK] RDS dang khoi dong lai!" -ForegroundColor Green
            Write-Host "[OK] Vui long cho 3-5 phut de instance san sang (Available)." -ForegroundColor DarkGreen
            Write-Host "[OK] Chay '.\stop_rds.ps1 -Action status' de kiem tra." -ForegroundColor DarkGreen
        }
        catch {
            Write-Host "[ERROR] Khong the start RDS: $_" -ForegroundColor Red
        }
    }

    "status" {
        Write-Host "[FinOps] Dang kiem tra trang thai RDS..." -ForegroundColor Cyan
        Write-Host ""

        try {
            $result = aws rds describe-db-instances `
                --db-instance-identifier $InstanceId `
                --region $Region `
                --query "DBInstances[0].{Status:DBInstanceStatus,Endpoint:Endpoint.Address,Port:Endpoint.Port,AZ:AvailabilityZone,Class:DBInstanceClass,MultiAZ:MultiAZ,Storage:AllocatedStorage,Engine:Engine,EngineVersion:EngineVersion}" `
                --output table

            Write-Host $result
            Write-Host ""

            # Hiển thị gợi ý hành động tiếp theo
            $status = aws rds describe-db-instances `
                --db-instance-identifier $InstanceId `
                --region $Region `
                --query "DBInstances[0].DBInstanceStatus" `
                --output text

            if ($status -eq "available") {
                Write-Host "[TIP] RDS dang chay. Neu khong can, hay chay: .\stop_rds.ps1 -Action stop" -ForegroundColor Yellow
            }
            elseif ($status -eq "stopped") {
                Write-Host "[TIP] RDS da tat. Khi can test, chay: .\stop_rds.ps1 -Action start" -ForegroundColor Green
            }
            else {
                Write-Host "[INFO] RDS dang o trang thai: $status. Vui long cho..." -ForegroundColor DarkYellow
            }
        }
        catch {
            Write-Host "[ERROR] Khong the kiem tra trang thai: $_" -ForegroundColor Red
        }
    }
}

Write-Host ""
