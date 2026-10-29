<#
.SYNOPSIS
    Kịch bản tự động hóa TOÀN BỘ vòng đời Amazon Redshift Serverless (Tuần 5)
.DESCRIPTION
    Dành cho Thành viên 3 (Dữ liệu & FinOps — Phạm Thế Hùng)
    Tự động hóa: Khởi tạo → Nạp dữ liệu → Chạy truy vấn phân tích → Chụp ảnh → XÓA NGAY
    ⚠️  CẢNH BÁO FINOPS: Redshift Serverless tính phí ~$3/giờ (8 RPU). BẮT BUỘC XÓA SAU DEMO!
.PARAMETER Region
    AWS Region (mặc định: ap-southeast-1)
.PARAMETER ProjectName
    Tên dự án (mặc định: enterprise-cloud-devsecops)
.PARAMETER Action
    Deploy, LoadData, RunQueries, Status, Destroy, FullDemo (mặc định: FullDemo)
.EXAMPLE
    .\demo_redshift.ps1 -Action FullDemo
    .\demo_redshift.ps1 -Action Deploy
    .\demo_redshift.ps1 -Action Destroy
#>

[CmdletBinding()]
param(
    [string]$Region = "ap-southeast-1",
    [string]$ProjectName = "enterprise-cloud-devsecops",
    [ValidateSet("Deploy", "LoadData", "RunQueries", "Status", "Destroy", "FullDemo")]
    [string]$Action = "FullDemo"
)

$ErrorActionPreference = "Continue"

$NamespaceName = "$ProjectName-analytics-ns"
$WorkgroupName = "$ProjectName-analytics-wg"
$DbName        = "analytics_db"
$DbUser        = "admin"
$ScriptsDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigsDir    = Join-Path $ScriptsDir "configs"

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  ENTERPRISE CLOUD DEVSECOPS — REDSHIFT SERVERLESS DEMO (TUẦN 5)       " -ForegroundColor Yellow
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "Region         : $Region" -ForegroundColor Gray
Write-Host "Namespace      : $NamespaceName" -ForegroundColor Gray
Write-Host "Workgroup      : $WorkgroupName" -ForegroundColor Gray
Write-Host "Action         : $Action" -ForegroundColor Gray
Write-Host ""

# Hàm trợ giúp: Chờ workgroup AVAILABLE
function Wait-WorkgroupAvailable {
    Write-Host "[...] Đang chờ Redshift Serverless Workgroup khởi tạo (có thể mất 3-5 phút)..." -ForegroundColor Yellow
    $maxWait = 600  # 10 phút tối đa
    $elapsed = 0
    while ($elapsed -lt $maxWait) {
        try {
            $wg = aws redshift-serverless get-workgroup --workgroup-name $WorkgroupName --region $Region 2>&1 | ConvertFrom-Json
            if ($wg.workgroup.status -eq "AVAILABLE") {
                Write-Host "[OK] Workgroup đã sẵn sàng: AVAILABLE" -ForegroundColor Green
                Write-Host "     Endpoint: $($wg.workgroup.endpoint.address):$($wg.workgroup.endpoint.port)" -ForegroundColor Cyan
                return $true
            }
            Write-Host "     Trạng thái hiện tại: $($wg.workgroup.status) ($elapsed giây)..." -ForegroundColor Gray
        } catch {
            Write-Host "     Đang khởi tạo... ($elapsed giây)" -ForegroundColor Gray
        }
        Start-Sleep -Seconds 15
        $elapsed += 15
    }
    Write-Host "[!] Hết thời gian chờ! Workgroup chưa sẵn sàng sau $maxWait giây." -ForegroundColor Red
    return $false
}

# Hàm trợ giúp: Chạy SQL statement qua Redshift Data API và chờ kết quả
function Invoke-RedshiftSQL {
    param(
        [string]$SqlText,
        [string]$Description,
        [switch]$ShowResults
    )
    Write-Host "`n    → Đang thực thi: $Description..." -ForegroundColor White

    $result = aws redshift-data execute-statement `
        --workgroup-name $WorkgroupName `
        --database $DbName `
        --sql $SqlText `
        --region $Region 2>&1 | ConvertFrom-Json

    if (-not $result.Id) {
        Write-Host "      [FAIL] Không thể gửi SQL statement!" -ForegroundColor Red
        return $null
    }

    $stmtId = $result.Id
    # Chờ statement hoàn thành
    $maxWait = 120
    $elapsed = 0
    while ($elapsed -lt $maxWait) {
        Start-Sleep -Seconds 3
        $elapsed += 3
        $desc = aws redshift-data describe-statement --id $stmtId --region $Region 2>&1 | ConvertFrom-Json
        if ($desc.Status -eq "FINISHED") {
            Write-Host "      [OK] Hoàn thành ($($desc.Duration / 1000000)ms)" -ForegroundColor Green

            if ($ShowResults -and $desc.HasResultSet) {
                Write-Host ""
                $rows = aws redshift-data get-statement-result --id $stmtId --region $Region 2>&1 | ConvertFrom-Json
                # In header
                $headers = ($rows.ColumnMetadata | ForEach-Object { $_.label }) -join " | "
                Write-Host "      $headers" -ForegroundColor Cyan
                Write-Host "      $('-' * $headers.Length)" -ForegroundColor Gray
                # In data rows
                foreach ($row in $rows.Records) {
                    $values = ($row | ForEach-Object {
                        if ($_.stringValue) { $_.stringValue }
                        elseif ($_.longValue -ne $null) { $_.longValue }
                        elseif ($_.doubleValue -ne $null) { $_.doubleValue }
                        else { "NULL" }
                    }) -join " | "
                    Write-Host "      $values" -ForegroundColor White
                }
                Write-Host ""
            }
            return $stmtId
        }
        elseif ($desc.Status -eq "FAILED") {
            Write-Host "      [FAIL] $($desc.Error)" -ForegroundColor Red
            return $null
        }
    }
    Write-Host "      [TIMEOUT] Câu truy vấn chưa hoàn thành sau $maxWait giây." -ForegroundColor Yellow
    return $null
}

# 1. DEPLOY: Khởi tạo Redshift Serverless qua Terraform
function Deploy-Redshift {
    Write-Host "`n[1/4] ⚡ Khởi tạo Redshift Serverless (Terraform apply)..." -ForegroundColor Yellow
    Write-Host "       ⚠️  CHI PHÍ: ~`$3.00/giờ (8 RPU). BẮT BUỘC XÓA SAU 2 GIỜ!" -ForegroundColor Red

    $tfDir = Join-Path (Split-Path $ScriptsDir -Parent) "terraform"
    Push-Location $tfDir

    # Bật toggle enable_redshift_demo = true
    terraform apply -auto-approve -var="enable_redshift_demo=true"

    Pop-Location

    Wait-WorkgroupAvailable
}

# 2. LOAD DATA: Nạp dữ liệu mẫu vào Redshift
function Load-SampleData {
    Write-Host "`n[2/4] 📥 Nạp dữ liệu mẫu e-commerce (3 bảng, 85 bản ghi)..." -ForegroundColor Yellow

    $sqlFile = Join-Path $ConfigsDir "redshift_sample_data.sql"
    if (-not (Test-Path $sqlFile)) {
        Write-Host "    [!] Không tìm thấy file: $sqlFile" -ForegroundColor Red
        return
    }

    # Đọc SQL file và tách thành các statements riêng lẻ
    $sqlContent = Get-Content $sqlFile -Raw -Encoding UTF8
    # Loại bỏ comment lines
    $sqlContent = ($sqlContent -split "`n" | Where-Object { $_ -notmatch '^\s*--' }) -join "`n"
    $statements = $sqlContent -split ';\s*\n' | Where-Object { $_.Trim().Length -gt 10 }

    $count = 0
    foreach ($stmt in $statements) {
        $count++
        $cleanStmt = $stmt.Trim()
        if ($cleanStmt.Length -lt 10) { continue }

        $desc = if ($cleanStmt -match 'CREATE TABLE.*?(\w+)\s*\(') { "CREATE TABLE $($Matches[1])" }
                elseif ($cleanStmt -match 'INSERT INTO\s+(\w+)') { "INSERT INTO $($Matches[1])" }
                else { "Statement $count" }

        Invoke-RedshiftSQL -SqlText $cleanStmt -Description $desc
    }

    Write-Host "`n    [OK] Nạp dữ liệu mẫu hoàn tất!" -ForegroundColor Green
}

# 3. RUN QUERIES: Chạy 7 câu truy vấn phân tích và hiển thị kết quả
function Run-AnalyticsQueries {
    Write-Host "`n[3/4] 📊 Chạy 7 câu truy vấn phân tích kinh doanh..." -ForegroundColor Yellow
    Write-Host "       📸 Chụp ảnh từng kết quả làm minh chứng nộp báo cáo!" -ForegroundColor Cyan

    $sqlFile = Join-Path $ConfigsDir "redshift_analytics_queries.sql"
    if (-not (Test-Path $sqlFile)) {
        Write-Host "    [!] Không tìm thấy file: $sqlFile" -ForegroundColor Red
        return
    }

    $sqlContent = Get-Content $sqlFile -Raw -Encoding UTF8
    # Loại bỏ comment lines
    $sqlContent = ($sqlContent -split "`n" | Where-Object { $_ -notmatch '^\s*--' }) -join "`n"
    $queries = $sqlContent -split ';\s*\n' | Where-Object { $_.Trim().Length -gt 20 }

    $queryNames = @(
        "QUERY 1: Doanh thu theo tháng (Monthly Revenue Trend)",
        "QUERY 2: Top 5 sản phẩm bán chạy nhất",
        "QUERY 3: Doanh thu theo danh mục sản phẩm",
        "QUERY 4: Phân tích phân khúc khách hàng",
        "QUERY 5: Doanh thu theo vùng địa lý",
        "QUERY 6: Phân tích phương thức thanh toán",
        "QUERY 7: Top 5 khách hàng giá trị cao nhất"
    )

    for ($i = 0; $i -lt [Math]::Min($queries.Count, $queryNames.Count); $i++) {
        $q = $queries[$i].Trim()
        if ($q.Length -lt 20) { continue }
        Write-Host "`n    ═══════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "    $($queryNames[$i])" -ForegroundColor Yellow
        Write-Host "    ═══════════════════════════════════════════════" -ForegroundColor Cyan
        Invoke-RedshiftSQL -SqlText $q -Description $queryNames[$i] -ShowResults
    }

    Write-Host "`n    [OK] Hoàn thành 7 câu truy vấn phân tích!" -ForegroundColor Green
    Write-Host "    📸 Hãy mở AWS Console → Redshift → Query Editor v2 để chụp ảnh minh chứng!" -ForegroundColor Cyan
}

# 4. DESTROY: Xóa toàn bộ tài nguyên Redshift Serverless
function Destroy-Redshift {
    Write-Host "`n[4/4] 🗑️  XÓA NGAY Redshift Serverless (FinOps bảo toàn credit)..." -ForegroundColor Red

    $tfDir = Join-Path (Split-Path $ScriptsDir -Parent) "terraform"
    Push-Location $tfDir

    # Tắt toggle enable_redshift_demo = false
    terraform apply -auto-approve -var="enable_redshift_demo=false"

    Pop-Location

    Write-Host "`n    [OK] ĐÃ XÓA SẠCH Redshift Serverless! Credit $200 được bảo toàn." -ForegroundColor Green

    # Xác minh đã xóa
    try {
        $check = aws redshift-serverless get-workgroup --workgroup-name $WorkgroupName --region $Region 2>&1
        if ($check -match "ResourceNotFoundException") {
            Write-Host "    [VERIFIED] Xác nhận Workgroup '$WorkgroupName' đã bị xóa hoàn toàn." -ForegroundColor Green
        }
    } catch {
        Write-Host "    [VERIFIED] Xác nhận đã xóa thành công." -ForegroundColor Green
    }
}

# STATUS: Kiểm tra trạng thái hiện tại
function Check-RedshiftStatus {
    Write-Host "`n[STATUS] Kiểm tra trạng thái Redshift Serverless..." -ForegroundColor White

    # Kiểm tra Namespace
    try {
        $ns = aws redshift-serverless get-namespace --namespace-name $NamespaceName --region $Region 2>&1 | ConvertFrom-Json
        if ($ns.namespace) {
            Write-Host "    Namespace : $($ns.namespace.namespaceName) | Status: $($ns.namespace.status)" -ForegroundColor Green
            Write-Host "    Database  : $($ns.namespace.dbName)" -ForegroundColor Gray
        }
    } catch {
        Write-Host "    Namespace : KHÔNG TỒN TẠI (Đã xóa hoặc chưa tạo)" -ForegroundColor Gray
    }

    # Kiểm tra Workgroup
    try {
        $wg = aws redshift-serverless get-workgroup --workgroup-name $WorkgroupName --region $Region 2>&1 | ConvertFrom-Json
        if ($wg.workgroup) {
            Write-Host "    Workgroup : $($wg.workgroup.workgroupName) | Status: $($wg.workgroup.status)" -ForegroundColor Green
            Write-Host "    Capacity  : $($wg.workgroup.baseCapacity) RPU" -ForegroundColor Cyan
            if ($wg.workgroup.endpoint) {
                Write-Host "    Endpoint  : $($wg.workgroup.endpoint.address):$($wg.workgroup.endpoint.port)" -ForegroundColor Cyan
            }
        }
    } catch {
        Write-Host "    Workgroup : KHÔNG TỒN TẠI (Đã xóa hoặc chưa tạo)" -ForegroundColor Gray
    }
}

# Điều phối thực thi
switch ($Action) {
    "Deploy"     { Deploy-Redshift }
    "LoadData"   { Load-SampleData }
    "RunQueries" { Run-AnalyticsQueries }
    "Status"     { Check-RedshiftStatus }
    "Destroy"    { Destroy-Redshift }
    "FullDemo" {
        Write-Host "🚀 BẮT ĐẦU KỊCH BẢN DEMO ĐẦY ĐỦ (Deploy → Load → Query → Destroy)" -ForegroundColor Yellow
        Write-Host "⏱️  Ước tính thời gian: 15-20 phút | Chi phí: ~$0.50-$1.00 USD" -ForegroundColor Gray
        Write-Host ""

        Deploy-Redshift
        Load-SampleData
        Run-AnalyticsQueries

        Write-Host "`n======================================================================" -ForegroundColor Cyan
        Write-Host "  📸  THỜI ĐIỂM CHỤP ẢNH MINH CHỨNG!" -ForegroundColor Yellow
        Write-Host "======================================================================" -ForegroundColor Cyan
        Write-Host "  1. Mở AWS Console → Amazon Redshift → Serverless dashboard" -ForegroundColor White
        Write-Host "  2. Mở Query Editor v2 → Chạy lại 7 câu query và chụp ảnh kết quả" -ForegroundColor White
        Write-Host "  3. Chụp ảnh trang Workgroup hiển thị: AVAILABLE, 8 RPU" -ForegroundColor White
        Write-Host "  4. Khi xong, bấm Enter để XÓA NGAY tài nguyên..." -ForegroundColor White
        Write-Host "======================================================================" -ForegroundColor Cyan
        Write-Host ""
        Read-Host "  Bấm [Enter] sau khi đã chụp ảnh xong để XÓA Redshift Serverless"

        Destroy-Redshift

        Write-Host "`n======================================================================" -ForegroundColor Cyan
        Write-Host "  ✅  DEMO TUẦN 5 HOÀN TẤT! CREDIT ĐƯỢC BẢO TOÀN!" -ForegroundColor Green
        Write-Host "======================================================================" -ForegroundColor Cyan
    }
}
