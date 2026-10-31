# ==============================================================================
# SCRIPT TRIEN KHAI HA TANG 1-CLICK (POWERSHELL / WINDOWS)
# Du an: ENTERPRISE CLOUD & DEVSECOPS PLATFORM
# Vai tro: Thanh vien 1 (Nhom truong - Mang & IaC)
# Tuan 6: Toi uu hoa & Tu dong hoa ha tang
# ==============================================================================

[CmdletBinding()]
param (
    [switch]$AutoApprove = $false,
    [switch]$SkipAuthCheck = $false
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TerraformDir = Split-Path -Parent $ScriptDir

Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "  ENTERPRISE CLOUD & DEVSECOPS PLATFORM - 1-CLICK DEPLOYMENT  " -ForegroundColor Cyan
Write-Host "  Role: Member 1 (Network & Infrastructure as Code)            " -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Chuyen vao thu muc terraform
Set-Location -Path $TerraformDir
Write-Host "[1/6] Thu muc lam viec: $TerraformDir" -ForegroundColor Green

# 2. Kiem tra thong tin xac thuc AWS CLI
if (-not $SkipAuthCheck) {
    Write-Host "[2/6] Kiem tra quyen truy cap AWS CLI..." -ForegroundColor Yellow
    try {
        $caller = aws sts get-caller-identity --output json | ConvertFrom-Json
        Write-Host "       AWS Account : $($caller.Account)" -ForegroundColor Gray
        Write-Host "       ARN Identity: $($caller.Arn)" -ForegroundColor Gray
        Write-Host "       Xac thuc AWS thanh cong!" -ForegroundColor Green
    }
    catch {
        Write-Host "CANH BAO: Khong the ket noi AWS CLI! Hay kiem tra 'aws configure' hoac bien moi truong." -ForegroundColor Red
        $proceed = Read-Host "Ban co muon tiep tuc chay che do kiem tra cuc bo (validate) khong? (y/n)"
        if ($proceed -ne 'y' -and $proceed -ne 'Y') {
            Exit 1
        }
    }
} else {
    Write-Host "[2/6] Bo qua kiem tra AWS CLI (SkipAuthCheck)." -ForegroundColor Yellow
}

# 3. Kiem tra file cau hinh terraform.tfvars
Write-Host "[3/6] Kiem tra bien cau hinh (terraform.tfvars)..." -ForegroundColor Yellow
if (-not (Test-Path "terraform.tfvars")) {
    if (Test-Path "terraform.tfvars.example") {
        Write-Host "       Chua co terraform.tfvars. Dang tu dong copy tu terraform.tfvars.example..." -ForegroundColor Cyan
        Copy-Item -Path "terraform.tfvars.example" -Destination "terraform.tfvars"
        Write-Host "       Da tao terraform.tfvars mac dinh." -ForegroundColor Green
    } else {
        Write-Host "CANH BAO: Khong tim thay terraform.tfvars hay terraform.tfvars.example!" -ForegroundColor Red
    }
} else {
    Write-Host "       File terraform.tfvars da san sang." -ForegroundColor Green
}

# 4. Kiem tra cu phap va tinh hop le cua Terraform
Write-Host "[4/6] Khoi tao & Kiem tra tinh toan ven (Init & Validate)..." -ForegroundColor Yellow
terraform init -no-color
if ($LASTEXITCODE -ne 0) {
    Write-Host "LOI: 'terraform init' that bai!" -ForegroundColor Red
    Exit $LASTEXITCODE
}

terraform fmt -check
if ($LASTEXITCODE -ne 0) {
    Write-Host "       Canh bao dinh dang ma nguon. Dang tu dong format..." -ForegroundColor Cyan
    terraform fmt
}

terraform validate
if ($LASTEXITCODE -ne 0) {
    Write-Host "LOI: Cau hinh Terraform khong hop le ('terraform validate' that bai)!" -ForegroundColor Red
    Exit $LASTEXITCODE
}
Write-Host "       Ma nguon Terraform hoan toan hop le!" -ForegroundColor Green

# 5. Tao ke hoach trien khai (Plan)
Write-Host "[5/6] Lap ke hoach trien khai (Terraform Plan)..." -ForegroundColor Yellow
Write-Host "       LUU Y FINOPS: NAT Gateway (~`$0.045/h) va ALB (~`$0.0225/h) se tieu hao tu goi `$200." -ForegroundColor Magenta
terraform plan -out=tfplan
if ($LASTEXITCODE -ne 0) {
    Write-Host "LOI: Lap ke hoach 'terraform plan' that bai!" -ForegroundColor Red
    Exit $LASTEXITCODE
}

# 6. Xac nhan va Trien khai (Apply)
Write-Host ""
Write-Host "[6/6] San sang trien khai ha tang len AWS!" -ForegroundColor Yellow
if (-not $AutoApprove) {
    $confirm = Read-Host "Ban co chac chan muon trien khai ke hoach len AWS khong? (nhap 'yes' de xac nhan)"
    if ($confirm -ne "yes") {
        Write-Host "Da huy bo lenh trien khai. Ke hoach tam thoi 'tfplan' da duoc xoa." -ForegroundColor Yellow
        if (Test-Path "tfplan") { Remove-Item "tfplan" }
        Exit 0
    }
}

Write-Host "Dang thuc thi 'terraform apply'..." -ForegroundColor Cyan
terraform apply -auto-approve tfplan
$applyStatus = $LASTEXITCODE

if (Test-Path "tfplan") {
    Remove-Item "tfplan"
}

if ($applyStatus -eq 0) {
    Write-Host ""
    Write-Host "==============================================================" -ForegroundColor Green
    Write-Host "  TRIEN KHAI HA TANG THANH CONG (1-CLICK DEPLOY COMPLETE)     " -ForegroundColor Green
    Write-Host "==============================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "--- BANG THONG SO BAN GIAO CHO CAC THANH VIEN (OUTPUTS) ---" -ForegroundColor Cyan
    terraform output
    Write-Host ""
    Write-Host "GHI NHO FINOPS: Sau khi kiem thu xong, hay chay '.\scripts\destroy.ps1' de thu hoi tai nguyen." -ForegroundColor Yellow
} else {
    Write-Host "LOI: Qua trinh 'terraform apply' gap su co! Ma loi: $applyStatus" -ForegroundColor Red
    Exit $applyStatus
}
