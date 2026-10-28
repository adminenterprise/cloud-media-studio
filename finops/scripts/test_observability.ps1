<#
.SYNOPSIS
    Kịch bản kiểm thử tự động hóa Amazon CloudWatch & AWS CloudTrail (Tuần 4)
.DESCRIPTION
    Dành cho Thành viên 3 (Dữ liệu & FinOps — Phạm Thế Hùng)
    Kiểm tra trạng thái CloudWatch Dashboard, Log Groups (Retention 7 ngày), Alarms quá tải CPU > 70%,
    SNS Alert Email, trạng thái CloudTrail ghi vết kiểm toán và cấu hình S3 Glacier Lifecycle.
    Hỗ trợ mô phỏng kích hoạt chuông cảnh báo (Trigger Alarm) để kiểm thử gửi email trực tiếp khi demo.
.PARAMETER Region
    AWS Region (mặc định: ap-southeast-1)
.PARAMETER ProjectName
    Tên dự án (mặc định: enterprise-cloud-devsecops)
.PARAMETER Action
    Hành động: All, Status, TriggerAlarm, ResetAlarm, TailLogs (mặc định: All)
.EXAMPLE
    .\test_observability.ps1 -Action All
    .\test_observability.ps1 -Action Status
    .\test_observability.ps1 -Action TriggerAlarm
    .\test_observability.ps1 -Action ResetAlarm
#>

[CmdletBinding()]
param(
    [string]$Region = "ap-southeast-1",
    [string]$ProjectName = "enterprise-cloud-devsecops",
    [ValidateSet("All", "Status", "TriggerAlarm", "ResetAlarm", "TailLogs")]
    [string]$Action = "All"
)

$ErrorActionPreference = "Continue"

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  ENTERPRISE CLOUD DEVSECOPS — GIÁM SÁT & KIỂM TOÁN TUẦN 4 (FINOPS)   " -ForegroundColor Yellow
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "Region       : $Region" -ForegroundColor Gray
Write-Host "Project Name : $ProjectName" -ForegroundColor Gray
Write-Host "Action       : $Action" -ForegroundColor Gray
Write-Host ""

$DashboardName = "$ProjectName-observability-dashboard"
$RdsAlarmName  = "$ProjectName-rds-cpu-high-alert"
$ComputeAlarm  = "$ProjectName-compute-cpu-high-alert"
$StorageAlarm  = "$ProjectName-rds-free-storage-low-alert"
$BillingAlarm  = "$ProjectName-billing-estimated-charges-alert"
$TrailName     = "$ProjectName-audit-trail"
$TopicName     = "$ProjectName-alerts-topic"

# 1. Kiểm tra CloudWatch Dashboard
function Check-CloudWatchDashboard {
    Write-Host "[1/6] Kiểm tra CloudWatch Observability Dashboard: $DashboardName..." -ForegroundColor White
    try {
        $dash = aws cloudwatch get-dashboard --dashboard-name $DashboardName --region $Region 2>&1 | ConvertFrom-Json
        if ($dash.DashboardArn) {
            Write-Host "    [OK] Dashboard tồn tại: $($dash.DashboardName)" -ForegroundColor Green
            Write-Host "    [URL] https://$Region.console.aws.amazon.com/cloudwatch/home?region=$Region#dashboards:name=$DashboardName" -ForegroundColor Cyan
        } else {
            Write-Host "    [!] Chưa tìm thấy Dashboard: $DashboardName (Hãy apply Terraform hoặc kiểm tra quyền)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "    [!] Lỗi khi truy vấn Dashboard: $_" -ForegroundColor Red
    }
}

# 2. Kiểm tra CloudWatch Log Groups & Retention (FinOps Guardrail = 7 ngày)
function Check-LogGroupsRetention {
    Write-Host "`n[2/6] Kiểm tra CloudWatch Log Groups & Chính sách lưu trữ (Retention 7 ngày)..." -ForegroundColor White
    $expectedPrefixes = @(
        "/ecs/$ProjectName-backend-app",
        "/aws/rds/instance/$ProjectName-mysql-primary",
        "/aws/cloudtrail/$ProjectName-audit-logs"
    )

    foreach ($p in $expectedPrefixes) {
        try {
            $lg = aws logs describe-log-groups --log-group-name-prefix $p --region $Region 2>&1 | ConvertFrom-Json
            if ($lg.logGroups -and $lg.logGroups.Count -gt 0) {
                foreach ($group in $lg.logGroups) {
                    $ret = if ($group.retentionInDays) { "$($group.retentionInDays) ngày" } else { "Never Expire (CẢNH BÁO TỐN TIỀN!)" }
                    $color = if ($group.retentionInDays -le 7) { "Green" } else { "Red" }
                    Write-Host "    [OK] Log Group: $($group.logGroupName) | Retention: $ret" -ForegroundColor $color
                }
            } else {
                Write-Host "    [-] Log Group tiền tố $p: Chưa tạo hoặc rỗng" -ForegroundColor Gray
            }
        } catch {
            Write-Host "    [!] Lỗi kiểm tra Log Group $p: $_" -ForegroundColor Red
        }
    }
}

# 3. Kiểm tra CloudWatch Alarms (CPU > 70% & Hạn mức chi phí)
function Check-CloudWatchAlarms {
    Write-Host "`n[3/6] Kiểm tra CloudWatch Metric Alarms (CPU > 70%, Storage, Billing)..." -ForegroundColor White
    $alarmList = @($RdsAlarmName, $ComputeAlarm, $StorageAlarm, $BillingAlarm)

    try {
        $alarms = aws cloudwatch describe-alarms --alarm-names $alarmList --region $Region 2>&1 | ConvertFrom-Json
        if ($alarms.MetricAlarms -and $alarms.MetricAlarms.Count -gt 0) {
            foreach ($a in $alarms.MetricAlarms) {
                $stateColor = switch ($a.StateValue) {
                    "OK" { "Green" }
                    "ALARM" { "Red" }
                    default { "Yellow" }
                }
                Write-Host "    - Alarm: $($a.AlarmName)" -ForegroundColor White
                Write-Host "      Metric    : $($a.Namespace)/$($a.MetricName) | Ngưỡng: $($a.ComparisonOperator) $($a.Threshold)" -ForegroundColor Gray
                Write-Host "      Trạng thái: $($a.StateValue)" -ForegroundColor $stateColor
            }
        } else {
            Write-Host "    [!] Không tìm thấy các Alarms chỉ định. Hãy kiểm tra lại tên hoặc triển khai Terraform." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "    [!] Lỗi khi truy vấn Alarms: $_" -ForegroundColor Red
    }
}

# 4. Kiểm tra SNS Topic & Danh sách Email đăng ký cảnh báo
function Check-SnsSubscriptions {
    Write-Host "`n[4/6] Kiểm tra SNS Alerts Topic & Danh sách Email nhận thông báo..." -ForegroundColor White
    try {
        $topics = aws sns list-topics --region $Region 2>&1 | ConvertFrom-Json
        $matched = $topics.Topics | Where-Object { $_.TopicArn -like "*$TopicName*" }

        if ($matched) {
            Write-Host "    [OK] SNS Topic ARN: $($matched.TopicArn)" -ForegroundColor Green
            $subs = aws sns list-subscriptions-by-topic --topic-arn $matched.TopicArn --region $Region 2>&1 | ConvertFrom-Json
            if ($subs.Subscriptions -and $subs.Subscriptions.Count -gt 0) {
                foreach ($s in $subs.Subscriptions) {
                    $status = if ($s.SubscriptionArn -eq "PendingConfirmation") { "Đang chờ xác nhận Email (Pending)" } else { "Đã xác nhận (Confirmed)" }
                    $c = if ($s.SubscriptionArn -eq "PendingConfirmation") { "Yellow" } else { "Green" }
                    Write-Host "      + Endpoint: $($s.Endpoint) ($status)" -ForegroundColor $c
                }
            } else {
                Write-Host "      [-] Chưa có Email nào đăng ký nhận tin." -ForegroundColor Yellow
            }
        } else {
            Write-Host "    [-] Chưa tìm thấy SNS Topic $TopicName" -ForegroundColor Gray
        }
    } catch {
        Write-Host "    [!] Lỗi khi truy vấn SNS: $_" -ForegroundColor Red
    }
}

# 5. Kiểm tra AWS CloudTrail & S3 Glacier Lifecycle
function Check-CloudTrailAudit {
    Write-Host "`n[5/6] Kiểm tra AWS CloudTrail Audit Trail & S3 Glacier Lifecycle..." -ForegroundColor White
    try {
        $trail = aws cloudtrail describe-trails --trail-name-list $TrailName --region $Region 2>&1 | ConvertFrom-Json
        if ($trail.trailList -and $trail.trailList.Count -gt 0) {
            $t = $trail.trailList[0]
            Write-Host "    [OK] CloudTrail Trail : $($t.Name)" -ForegroundColor Green
            Write-Host "         S3 Bucket Target : $($t.S3BucketName)" -ForegroundColor Cyan
            Write-Host "         Log Validation   : $($t.LogFileValidationEnabled)" -ForegroundColor Gray
            Write-Host "         CW Log Group     : $($t.CloudWatchLogsLogGroupArn)" -ForegroundColor Gray

            # Kiểm tra trạng thái logging thực tế
            $status = aws cloudtrail get-trail-status --name $TrailName --region $Region 2>&1 | ConvertFrom-Json
            $isLogging = $status.IsLogging
            $logColor = if ($isLogging) { "Green" } else { "Red" }
            Write-Host "         Trạng thái Ghi   : IsLogging = $isLogging" -ForegroundColor $logColor

            # Kiểm tra S3 Lifecycle của Bucket lưu Audit Logs
            if ($t.S3BucketName) {
                try {
                    $lifecycle = aws s3api get-bucket-lifecycle-configuration --bucket $t.S3BucketName 2>&1 | ConvertFrom-Json
                    if ($lifecycle.Rules) {
                        Write-Host "`n    [OK] S3 Lifecycle Rules trên Bucket Audit ($($t.S3BucketName)):" -ForegroundColor Green
                        foreach ($rule in $lifecycle.Rules) {
                            $transStr = if ($rule.Transitions) { "Chuyển sang $($rule.Transitions[0].StorageClass) sau $($rule.Transitions[0].Days) ngày" } else { "" }
                            $expStr = if ($rule.Expiration) { "Xóa vĩnh viễn sau $($rule.Expiration.Days) ngày" } else { "" }
                            Write-Host "         - Quy tắc: $($rule.ID) | $transStr | $expStr" -ForegroundColor Cyan
                        }
                    }
                } catch {
                    Write-Host "         [-] Chưa đọc được S3 Lifecycle: $_" -ForegroundColor Gray
                }
            }
        } else {
            Write-Host "    [-] Không tìm thấy CloudTrail trail $TrailName" -ForegroundColor Gray
        }
    } catch {
        Write-Host "    [!] Lỗi khi kiểm tra CloudTrail: $_" -ForegroundColor Red
    }
}

# 6. Kiểm tra các sự kiện API gần nhất ghi vết bởi CloudTrail
function Check-RecentApiEvents {
    Write-Host "`n[6/6] Truy vấn 5 sự kiện gọi API gần nhất được CloudTrail ghi vết..." -ForegroundColor White
    try {
        $events = aws cloudtrail lookup-events --max-results 5 --region $Region 2>&1 | ConvertFrom-Json
        if ($events.Events -and $events.Events.Count -gt 0) {
            foreach ($e in $events.Events) {
                Write-Host "    [$($e.EventTime)] Event: $($e.EventName) | User: $($e.Username) | Service: $($e.EventSource)" -ForegroundColor Gray
            }
        } else {
            Write-Host "    [-] Chưa có sự kiện API nào được ghi nhận gần đây." -ForegroundColor Gray
        }
    } catch {
        Write-Host "    [-] Không thể truy vấn sự kiện: $_" -ForegroundColor Gray
    }
}

# HÀNH ĐỘNG MÔ PHỎNG KÍCH HOẠT CHUÔNG BÁO ĐỘNG (TRIGGER ALARM DEMO)
function Trigger-SimulatedAlarm {
    Write-Host "`n🚨 [DEMO MÀN 3] Đang mô phỏng quá tải CPU 85% trên RDS MySQL..." -ForegroundColor Yellow
    Write-Host "   Alarm Name: $RdsAlarmName" -ForegroundColor White

    aws cloudwatch set-alarm-state `
        --alarm-name $RdsAlarmName `
        --state-value ALARM `
        --state-reason "Live Demo: Simulated CPU 85% overload on RDS MySQL - Trigger SNS Email to team" `
        --region $Region

    Write-Host "   [SUCCESS] Đã chuyển trạng thái Alarm sang 'ALARM' thành công!" -ForegroundColor Green
    Write-Host "   📧 Email cảnh báo tự động đã được SNS gửi tới hộp thư của nhóm!" -ForegroundColor Cyan
    Write-Host "   Hãy mở hộp thư (và mục Spam) để kiểm tra email tiêu đề: ALARM: $RdsAlarmName" -ForegroundColor Yellow
}

# HÀNH ĐỘNG ĐẶT LẠI TRẠNG THÁI OK
function Reset-AlarmStatus {
    Write-Host "`n✅ Đang trả lại trạng thái bình thường (OK) cho Alarm..." -ForegroundColor Green
    Write-Host "   Alarm Name: $RdsAlarmName" -ForegroundColor White

    aws cloudwatch set-alarm-state `
        --alarm-name $RdsAlarmName `
        --state-value OK `
        --state-reason "Live Demo: Workload normalized under 70% threshold" `
        --region $Region

    Write-Host "   [SUCCESS] Đã trả lại trạng thái 'OK' cho Alarm thành công!" -ForegroundColor Green
}

# Điều phối thực thi theo Action
switch ($Action) {
    "Status" {
        Check-CloudWatchDashboard
        Check-LogGroupsRetention
        Check-CloudWatchAlarms
        Check-SnsSubscriptions
        Check-CloudTrailAudit
    }
    "TriggerAlarm" {
        Trigger-SimulatedAlarm
    }
    "ResetAlarm" {
        Reset-AlarmStatus
    }
    "TailLogs" {
        Check-RecentApiEvents
    }
    "All" {
        Check-CloudWatchDashboard
        Check-LogGroupsRetention
        Check-CloudWatchAlarms
        Check-SnsSubscriptions
        Check-CloudTrailAudit
        Check-RecentApiEvents

        Write-Host "`n----------------------------------------------------------------------" -ForegroundColor Cyan
        Write-Host "  MẸO DEMO BẢO VỆ ĐỒ ÁN (MÀN 3 — FINOPS & MONITORING):" -ForegroundColor Yellow
        Write-Host "  1. Chạy '.\test_observability.ps1 -Action TriggerAlarm' để bắn email cảnh báo tức thì!" -ForegroundColor White
        Write-Host "  2. Mở CloudWatch Dashboard trực quan hóa hạ tầng theo đường dẫn URL trên." -ForegroundColor White
        Write-Host "  3. Chạy '.\test_observability.ps1 -Action ResetAlarm' để trả lại trạng thái OK." -ForegroundColor White
        Write-Host "----------------------------------------------------------------------" -ForegroundColor Cyan
    }
}
