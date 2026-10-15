<#
.SYNOPSIS
    Kịch bản kiểm thử tự động hóa DynamoDB (User Sessions & Cart) và S3 Glacier Lifecycle
.DESCRIPTION
    Dành cho Thành viên 3 (Dữ liệu & FinOps — Phạm Thế Hùng)
    Kiểm tra trạng thái bảng, ghi/đọc dữ liệu mẫu, xác thực cấu hình TTL và S3 Lifecycle.
.PARAMETER Region
    AWS Region (mặc định: ap-southeast-1)
.PARAMETER ProjectName
    Tên dự án (mặc định: enterprise-cloud-devsecops)
.PARAMETER Action
    Hành động: All, Status, TestCrud, CheckS3, Cleanup (mặc định: All)
.EXAMPLE
    .\test_dynamodb.ps1 -Action All
    .\test_dynamodb.ps1 -Action Status
    .\test_dynamodb.ps1 -Action Cleanup
#>

[CmdletBinding()]
param(
    [string]$Region = "ap-southeast-1",
    [string]$ProjectName = "enterprise-cloud-devsecops",
    [ValidateSet("All", "Status", "TestCrud", "CheckS3", "Cleanup")]
    [string]$Action = "All"
)

$ErrorActionPreference = "Continue"

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  ENTERPRISE CLOUD DEVSECOPS — KIỂM THỬ DỮ LIỆU TUẦN 3 (FINOPS)       " -ForegroundColor Yellow
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "Region       : $Region" -ForegroundColor Gray
Write-Host "Project Name : $ProjectName" -ForegroundColor Gray
Write-Host "Action       : $Action" -ForegroundColor Gray
Write-Host ""

$SessionTable = "$ProjectName-user-sessions"
$CartTable    = "$ProjectName-cart"
$S3Bucket     = "$ProjectName-static-assets-$Region"

# Function kiểm tra bảng DynamoDB
function Check-DynamoTableStatus {
    param([string]$TableName)
    Write-Host "[+] Kiểm tra bảng DynamoDB: $TableName..." -ForegroundColor White
    try {
        $desc = aws dynamodb describe-table --table-name $TableName --region $Region 2>&1 | ConvertFrom-Json
        if ($desc.Table) {
            $status = $desc.Table.TableStatus
            $mode   = $desc.Table.BillingModeSummary.BillingMode
            if (-not $mode) { $mode = "PAY_PER_REQUEST" }
            $count  = $desc.Table.ItemCount
            Write-Host "    Trạng thái : $status" -ForegroundColor Green
            Write-Host "    Billing    : $mode (FinOps On-Demand Optimized)" -ForegroundColor Cyan
            Write-Host "    Số items   : $count" -ForegroundColor Gray
        } else {
            Write-Host "    [!] Không tìm thấy bảng $TableName trên AWS!" -ForegroundColor Red
            return $false
        }

        # Kiểm tra TTL
        $ttl = aws dynamodb describe-time-to-live --table-name $TableName --region $Region 2>&1 | ConvertFrom-Json
        $ttlStatus = $ttl.TimeToLiveDescription.TimeToLiveStatus
        $ttlAttr   = $ttl.TimeToLiveDescription.AttributeName
        Write-Host "    TTL Status : $ttlStatus (Attribute: $ttlAttr)" -ForegroundColor Yellow
        return $true
    } catch {
        Write-Host "    [!] Lỗi khi truy vấn bảng $TableName : $_" -ForegroundColor Red
        return $false
    }
}

# Function kiểm thử ghi và đọc dữ liệu (CRUD Test)
function Test-DynamoCrud {
    Write-Host "`n--- [1] KIỂM THỬ THAO TÁC TRÊN USER SESSIONS TABLE ---" -ForegroundColor White
    $testSessionId = "sess_demo_week3_$(Get-Random)"
    $testUserId    = "user_hungpham_dev"
    $nowEpoch      = [int][double]::Parse((Get-Date -UFormat %s))
    $expireEpoch   = $nowEpoch + 604800 # 7 ngày sau

    Write-Host "  -> Ghi User Session mới ($testSessionId)..." -ForegroundColor White
    $itemJson = @"
{
    "sessionId": {"S": "$testSessionId"},
    "userId": {"S": "$testUserId"},
    "createdAt": {"N": "$nowEpoch"},
    "expiresAt": {"N": "$expireEpoch"},
    "device": {"S": "DevSecOps Workstation - Windows 11"},
    "role": {"S": "Member3-Data-FinOps"}
}
"@
    aws dynamodb put-item --table-name $SessionTable --item $itemJson --region $Region | Out-Null
    Write-Host "     [OK] Đã ghi thành công User Session vào DynamoDB!" -ForegroundColor Green

    Write-Host "  -> Đọc lại User Session theo Partition Key (sessionId)..." -ForegroundColor White
    $getRes = aws dynamodb get-item --table-name $SessionTable --key "{\`"sessionId\`": {\`"S\`": \`"$testSessionId\`"}}" --region $Region | ConvertFrom-Json
    if ($getRes.Item) {
        Write-Host "     [OK] Dữ liệu trả về tức thì (Single-digit ms):" -ForegroundColor Green
        Write-Host "          UserId : $($getRes.Item.userId.S)" -ForegroundColor Cyan
        Write-Host "          Device : $($getRes.Item.device.S)" -ForegroundColor Cyan
        Write-Host "          Expires: $($getRes.Item.expiresAt.N) (TTL Timestamp)" -ForegroundColor Yellow
    }

    Write-Host "  -> Truy vấn qua Global Secondary Index (userId-createdAt-index)..." -ForegroundColor White
    $queryRes = aws dynamodb query --table-name $SessionTable --index-name "userId-createdAt-index" `
        --key-condition-expression "userId = :uid" `
        --expression-attribute-values "{\`":uid\`": {\`"S\`": \`"$testUserId\`"}}" `
        --region $Region | ConvertFrom-Json
    Write-Host "     [OK] Tìm thấy $($queryRes.Count) session(s) qua GSI cho user $testUserId!" -ForegroundColor Green

    Write-Host "`n--- [2] KIỂM THỬ THAO TÁC TRÊN SHOPPING CART TABLE ---" -ForegroundColor White
    $testItemId = "item_aws_cloud_cert_01"
    Write-Host "  -> Thêm sản phẩm vào Giỏ hàng cho User ($testUserId)..." -ForegroundColor White
    $cartJson = @"
{
    "userId": {"S": "$testUserId"},
    "itemId": {"S": "$testItemId"},
    "title": {"S": "AWS Certified Solutions Architect Study Kit"},
    "quantity": {"N": "2"},
    "unitPrice": {"N": "49.99"},
    "expiresAt": {"N": "$expireEpoch"}
}
"@
    aws dynamodb put-item --table-name $CartTable --item $cartJson --region $Region | Out-Null
    Write-Host "     [OK] Đã thêm sản phẩm vào Cart thành công!" -ForegroundColor Green

    Write-Host "  -> Đọc Giỏ hàng theo Composite Key (userId + itemId)..." -ForegroundColor White
    $cartRes = aws dynamodb get-item --table-name $CartTable `
        --key "{\`"userId\`": {\`"S\`": \`"$testUserId\`"}, \`"itemId\`": {\`"S\`": \`"$testItemId\`"}}" `
        --region $Region | ConvertFrom-Json
    if ($cartRes.Item) {
        Write-Host "     [OK] Chi tiết sản phẩm trong giỏ hàng:" -ForegroundColor Green
        Write-Host "          Sản phẩm: $($cartRes.Item.title.S)" -ForegroundColor Cyan
        Write-Host "          Số lượng: $($cartRes.Item.quantity.N)" -ForegroundColor Cyan
        Write-Host "          Đơn giá : $$($cartRes.Item.unitPrice.N) USD" -ForegroundColor Cyan
    }

    # Lưu lại để cleanup
    $script:lastSessionId = $testSessionId
    $script:lastUserId    = $testUserId
    $script:lastItemId    = $testItemId
}

# Function kiểm tra S3 Lifecycle
function Check-S3Lifecycle {
    Write-Host "`n--- [3] KIỂM TRA S3 LIFECYCLE CHUYỂN SANG S3 GLACIER (FINOPS) ---" -ForegroundColor White
    Write-Host "Bucket: $S3Bucket" -ForegroundColor White
    try {
        $rules = aws s3api get-bucket-lifecycle-configuration --bucket $S3Bucket --region $Region 2>&1 | ConvertFrom-Json
        if ($rules.Rules) {
            Write-Host "  [OK] Cấu hình S3 Lifecycle đang HOẠT ĐỘNG! Danh sách quy tắc:" -ForegroundColor Green
            foreach ($r in $rules.Rules) {
                Write-Host "  --------------------------------------------------" -ForegroundColor Gray
                Write-Host "  Rule ID : $($r.ID)" -ForegroundColor Yellow
                Write-Host "  Status  : $($r.Status)" -ForegroundColor Green
                if ($r.Filter.Prefix) {
                    Write-Host "  Prefix  : $($r.Filter.Prefix)" -ForegroundColor Cyan
                } else {
                    Write-Host "  Scope   : Toàn bộ Bucket" -ForegroundColor Cyan
                }
                if ($r.Transitions) {
                    foreach ($t in $r.Transitions) {
                        Write-Host "  Chuyển sang: $($t.StorageClass) sau $($t.Days) ngày (Tiết kiệm > 84% chi phí)" -ForegroundColor Green
                    }
                }
                if ($r.NoncurrentVersionTransitions) {
                    foreach ($nvt in $r.NoncurrentVersionTransitions) {
                        Write-Host "  Phiên bản cũ: Chuyển sang $($nvt.StorageClass) sau $($nvt.NoncurrentDays) ngày" -ForegroundColor Magenta
                    }
                }
                if ($r.NoncurrentVersionExpiration) {
                    Write-Host "  Phiên bản cũ: Tự động XÓA sau $($r.NoncurrentVersionExpiration.NoncurrentDays) ngày" -ForegroundColor Red
                }
                if ($r.AbortIncompleteMultipartUpload) {
                    Write-Host "  Hủy Multipart dang dở: sau $($r.AbortIncompleteMultipartUpload.DaysAfterInitiation) ngày" -ForegroundColor Gray
                }
            }
        } else {
            Write-Host "  [!] Chưa tìm thấy Lifecycle Configuration trên bucket $S3Bucket" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  [!] Không thể lấy Lifecycle Configuration: $_" -ForegroundColor Red
    }
}

# Function dọn dẹp dữ liệu test
function Cleanup-TestData {
    Write-Host "`n--- DỌN DẸP DỮ LIỆU KIỂM THỬ ---" -ForegroundColor White
    if ($script:lastSessionId) {
        Write-Host "  -> Xóa session test: $script:lastSessionId" -ForegroundColor White
        aws dynamodb delete-item --table-name $SessionTable --key "{\`"sessionId\`": {\`"S\`": \`"$script:lastSessionId\`"}}" --region $Region | Out-Null
    }
    if ($script:lastUserId -and $script:lastItemId) {
        Write-Host "  -> Xóa cart test: $script:lastItemId" -ForegroundColor White
        aws dynamodb delete-item --table-name $CartTable --key "{\`"userId\`": {\`"S\`": \`"$script:lastUserId\`"}, \`"itemId\`": {\`"S\`": \`"$script:lastItemId\`"}}" --region $Region | Out-Null
    }
    Write-Host "  [OK] Đã dọn dẹp bản ghi kiểm thử thành công!" -ForegroundColor Green
}

# Điều phối hành động
switch ($Action) {
    "Status" {
        Check-DynamoTableStatus -TableName $SessionTable | Out-Null
        Check-DynamoTableStatus -TableName $CartTable | Out-Null
        Check-S3Lifecycle
    }
    "TestCrud" {
        Test-DynamoCrud
    }
    "CheckS3" {
        Check-S3Lifecycle
    }
    "Cleanup" {
        Cleanup-TestData
    }
    "All" {
        $t1 = Check-DynamoTableStatus -TableName $SessionTable
        $t2 = Check-DynamoTableStatus -TableName $CartTable
        if ($t1 -and $t2) {
            Test-DynamoCrud
        }
        Check-S3Lifecycle
        Write-Host "`n[TÙY CHỌN] Nếu muốn dọn dẹp các bản ghi test vừa tạo, chạy:" -ForegroundColor Gray
        Write-Host ".\test_dynamodb.ps1 -Action Cleanup" -ForegroundColor Yellow
    }
}

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "  HOÀN TẤT QUY TRÌNH KIỂM THỬ TUẦN 3 CHO MEMBER 3!                      " -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Cyan
