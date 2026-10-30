<#
.SYNOPSIS
    Kịch bản tự động hóa khởi tạo 4 IAM Users & Groups theo nguyên tắc Least Privilege qua AWS CLI.
.DESCRIPTION
    Tạo 4 nhóm:
    - Network-IaC-Group (Member 1)
    - Compute-Container-Group (Member 2)
    - Data-FinOps-Group (Member 3)
    - Security-DevSecOps-Group (Member 4)
    Tạo 4 users tương ứng, gắn vào group, áp dụng chính sách mật khẩu nghiêm ngặt và gắn custom policy.
.EXAMPLE
    .\setup_iam_users.ps1
#>

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  IAM LEAST PRIVILEGE AUTOMATION SCRIPT - TUẦN 1" -ForegroundColor Cyan
Write-Host "  Phân mảng: Thành viên 3 (Dữ liệu & FinOps)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Error "AWS CLI chưa được cài đặt hoặc chưa thêm vào PATH. Vui lòng cài đặt AWS CLI trước."
    exit 1
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigDir = Join-Path $ScriptDir "configs"

# 1. Cấu hình Password Policy
Write-Host "[1/5] Thiết lập chính sách mật khẩu mạnh cho tài khoản AWS..." -ForegroundColor Yellow
aws iam update-account-password-policy `
    --minimum-password-length 12 `
    --require-symbols `
    --require-numbers `
    --require-uppercase-characters `
    --require-lowercase-characters `
    --allow-users-to-change-password `
    --max-password-age 90 `
    --password-reuse-prevention 3

# 2. Định nghĩa danh sách nhóm và chính sách
$Roles = @(
    @{
        GroupName  = "Network-IaC-Group"
        UserName   = "member1-network-iac"
        PolicyName = "EnterpriseCloud-Member1-NetworkIaC-Policy"
        PolicyFile = "policy_member1_network.json"
    },
    @{
        GroupName  = "Compute-Container-Group"
        UserName   = "member2-compute-container"
        PolicyName = "EnterpriseCloud-Member2-ComputeContainer-Policy"
        PolicyFile = "policy_member2_compute.json"
    },
    @{
        GroupName  = "Data-FinOps-Group"
        UserName   = "member3-data-finops"
        PolicyName = "EnterpriseCloud-Member3-DataFinOps-Policy"
        PolicyFile = "policy_member3_data.json"
    },
    @{
        GroupName  = "Security-DevSecOps-Group"
        UserName   = "member4-security-devsecops"
        PolicyName = "EnterpriseCloud-Member4-SecurityDevSecOps-Policy"
        PolicyFile = "policy_member4_security.json"
    }
)

# 3. Tạo Base Policy dùng chung
Write-Host "[2/5] Tạo và gắn Base Policy (đổi pass, MFA, xem Budgets)..." -ForegroundColor Yellow
$BasePolicyFile = Join-Path $ConfigDir "policy_common_base.json"
$BasePolicyArn = (aws iam list-policies --query "Policies[?PolicyName=='EnterpriseCloud-CommonBase-Policy'].Arn" --output text 2>$null)
if (-not $BasePolicyArn) {
    $BasePolicyArn = (aws iam create-policy --policy-name "EnterpriseCloud-CommonBase-Policy" --policy-document file://$BasePolicyFile --query "Policy.Arn" --output text)
    Write-Host "    -> Đã tạo Base Policy ARN: $BasePolicyArn" -ForegroundColor Green
} else {
    Write-Host "    -> Base Policy đã tồn tại: $BasePolicyArn" -ForegroundColor Gray
}

# 4. Tạo từng Group, User, Policy chuyên mảng
Write-Host "[3/5] Khởi tạo các IAM Groups và Users chuyên trách..." -ForegroundColor Yellow
foreach ($item in $Roles) {
    $grp = $item.GroupName
    $usr = $item.UserName
    $polName = $item.PolicyName
    $polFile = Join-Path $ConfigDir $item.PolicyFile

    Write-Host "  Processing: Group [$grp] - User [$usr]..." -ForegroundColor Cyan

    # Tạo group nếu chưa có
    aws iam get-group --group-name $grp 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        aws iam create-group --group-name $grp | Out-Null
        Write-Host "    + Tạo nhóm: $grp" -ForegroundColor Green
    }

    # Gắn Base Policy vào nhóm
    aws iam attach-group-policy --group-name $grp --policy-arn $BasePolicyArn 2>$null

    # Tạo Special Policy nếu chưa có
    $specialPolicyArn = (aws iam list-policies --query "Policies[?PolicyName=='$polName'].Arn" --output text 2>$null)
    if (-not $specialPolicyArn) {
        $specialPolicyArn = (aws iam create-policy --policy-name $polName --policy-document file://$polFile --query "Policy.Arn" --output text)
        Write-Host "    + Tạo chính sách chuyên trách: $polName" -ForegroundColor Green
    }
    aws iam attach-group-policy --group-name $grp --policy-arn $specialPolicyArn 2>$null

    # Tạo User nếu chưa có
    aws iam get-user --user-name $usr 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        aws iam create-user --user-name $usr | Out-Null
        Write-Host "    + Tạo người dùng: $usr" -ForegroundColor Green
    }

    # Thêm user vào group
    aws iam add-user-to-group --user-name $usr --group-name $grp 2>$null
    Write-Host "    + Gán $usr vào nhóm $grp" -ForegroundColor Gray
}

Write-Host "`n[4/5] Hoàn tất thiết lập phân quyền Least Privilege cho 4 thành viên!" -ForegroundColor Green
Write-Host "[5/5] Gợi ý bước tiếp theo:" -ForegroundColor Yellow
Write-Host "  1. Vào IAM Console -> Users -> Chọn User -> Security credentials -> Bấm 'Create login profile' để cấp mật khẩu ban đầu." -ForegroundColor White
Write-Host "  2. Yêu cầu thành viên bật Google Authenticator / Authy để kích hoạt MFA." -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan
