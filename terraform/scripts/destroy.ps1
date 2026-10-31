# ==============================================================================
# SCRIPT THU HOI HA TANG AN TOAN (POWERSHELL / WINDOWS)
# Du an: ENTERPRISE CLOUD & DEVSECOPS PLATFORM
# Vai tro: Thanh vien 1 (Nhom truong - Mang & IaC)
# Tuan 6: Toi uu hoa & Quan tri tai chinh (FinOps)
# ==============================================================================

[CmdletBinding()]
param (
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TerraformDir = Split-Path -Parent $ScriptDir

Write-Host "==============================================================" -ForegroundColor Red
Write-Host "  ENTERPRISE CLOUD & DEVSECOPS PLATFORM - DESTROY INFRASTRUCTURE" -ForegroundColor Red
Write-Host "  Role: Member 1 (FinOps Clean-Up Protocol)                    " -ForegroundColor Red
Write-Host "==============================================================" -ForegroundColor Red
Write-Host ""

Set-Location -Path $TerraformDir

Write-Host "CANH BAO QUAN TRONG:" -ForegroundColor Yellow
Write-Host "- Lenh nay se XOA TOAN BO tai nguyen mang da tao (VPCs, Subnets, Gateways, SGs, ALB, WAF, Peering)." -ForegroundColor Yellow
Write-Host "- Thao tac nay nham bao ve so du tai khoan $200 sau cac buoi demo/dien tap." -ForegroundColor Yellow
Write-Host ""

if (-not $Force) {
    Write-Host "De xac nhan, vui long nhap chinh xac cum tu: " -NoNewline -ForegroundColor White
    Write-Host "DESTROY" -ForegroundColor Red -NoNewline
    Write-Host " (hoac an Ctrl+C de huy bo): " -ForegroundColor White
    $confirmation = Read-Host

    if ($confirmation -ne "DESTROY") {
        Write-Host "Thao tac huy tai nguyen da bi huy bo. Khong co thay doi nao xay ra." -ForegroundColor Green
        Exit 0
    }
}

Write-Host "Dang thuc thi 'terraform destroy'..." -ForegroundColor Cyan
terraform destroy -auto-approve

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "==============================================================" -ForegroundColor Green
    Write-Host "  DA THU HOI TOAN BO HA TANG THANH CONG!                      " -ForegroundColor Green
    Write-Host "  Trang thai: An toan cho ngan sach FinOps ($200 Credit).     " -ForegroundColor Green
    Write-Host "==============================================================" -ForegroundColor Green
} else {
    Write-Host "LOI: Qua trinh 'terraform destroy' gap loi! Kiem tra tai nguyen phu thuoc con sot lai." -ForegroundColor Red
    Exit $LASTEXITCODE
}
