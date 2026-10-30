<#
.SYNOPSIS
    Kịch bản tự động hóa cấu hình AWS Budgets qua AWS CLI cho Thành viên 3 (Dữ liệu & FinOps).
.DESCRIPTION
    Tạo ngân sách $200 USD với các ngưỡng cảnh báo:
    - Cảnh báo 1: Thực tế đạt $20 (10%)
    - Cảnh báo 2: Thực tế đạt $50 (25%)
    - Cảnh báo 3: Dự báo tháng đạt 80% ($160)
.EXAMPLE
    .\setup_aws_budgets.ps1 -AccountId "123456789012" -Email "minhquan10092006@gmail.com"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$AccountId,

    [Parameter(Mandatory=$false)]
    [string]$Email = "minhquan10092006@gmail.com"
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  AWS BUDGETS FINOPS AUTOMATION SCRIPT - TUẦN 1" -ForegroundColor Cyan
Write-Host "  Phân mảng: Thành viên 3 (Dữ liệu & FinOps)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Kiểm tra AWS CLI
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Error "AWS CLI chưa được cài đặt hoặc chưa thêm vào PATH. Vui lòng cài đặt AWS CLI trước."
    exit 1
}

# Tự động lấy Account ID nếu không truyền vào
if (-not $AccountId) {
    Write-Host "[1/3] Đang truy vấn AWS Account ID từ thông tin đăng nhập hiện tại..." -ForegroundColor Yellow
    $AccountId = (aws sts get-caller-identity --query "Account" --output text 2>$null)
    if (-not $AccountId) {
        Write-Error "Không thể xác định AWS Account ID. Vui lòng chạy 'aws configure' hoặc truyền tham số -AccountId."
        exit 1
    }
}
Write-Host "-> AWS Account ID: $AccountId" -ForegroundColor Green

# Chuẩn bị file payload tạm thời
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BasePayloadPath = Join-Path $ScriptDir "configs\budget_payload.json"
$TempPayloadPath = Join-Path $ScriptDir "configs\budget_temp_resolved.json"

if (-not (Test-Path $BasePayloadPath)) {
    Write-Error "Không tìm thấy file mẫu cấu hình tại $BasePayloadPath"
    exit 1
}

Write-Host "[2/3] Đang cập nhật email thông báo ($Email) vào cấu hình budget..." -ForegroundColor Yellow
$jsonContent = Get-Content -Path $BasePayloadPath -Raw
$jsonContent = $jsonContent -replace "admin-cloud@example.com", $Email
Set-Content -Path $TempPayloadPath -Value $jsonContent

# Thực thi lệnh tạo budget qua AWS CLI
Write-Host "[3/3] Đang gọi AWS Budgets API để khởi tạo ngân sách $200 USD..." -ForegroundColor Yellow
try {
    $budgetData = Get-Content $TempPayloadPath | ConvertFrom-Json
    $budgetDef = $budgetData.Budget | ConvertTo-Json -Depth 10 -Compress
    $notifDef = $budgetData.NotificationsWithSubscribers | ConvertTo-Json -Depth 10 -Compress

    aws budgets create-budget `
        --account-id $AccountId `
        --budget "$budgetDef" `
        --notifications-with-subscribers "$notifDef"

    Write-Host "`n>>> THÀNH CÔNG: Đã khởi tạo AWS Budget 'enterprise-cloud-student-budget-200usd' thành công!" -ForegroundColor Green
    Write-Host "    - Tổng hạn mức: $200 USD" -ForegroundColor White
    Write-Host "    - Ngưỡng Cấp 1: Cảnh báo email khi chi tiêu thực tế >= $20 (10%)" -ForegroundColor White
    Write-Host "    - Ngưỡng Cấp 2: Cảnh báo email khẩn cấp khi chi tiêu thực tế >= $50 (25%)" -ForegroundColor White
    Write-Host "    - Ngưỡng Dự báo: Cảnh báo sớm khi dự báo đạt 80% ($160 USD)" -ForegroundColor White
    Write-Host "    - Email nhận tin: $Email" -ForegroundColor White
}
catch {
    Write-Error "Lỗi khi khởi tạo AWS Budget: $_"
}
finally {
    if (Test-Path $TempPayloadPath) {
        Remove-Item $TempPayloadPath -Force
    }
}
