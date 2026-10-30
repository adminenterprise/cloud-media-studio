#!/usr/bin/env bash
# ==============================================================================
# ENTERPRISE CLOUD DEVSECOPS — KIỂM THỬ GIÁM SÁT & KIỂM TOÁN TUẦN 4 (FINOPS)
# ==============================================================================
# Phân mảng: Thành viên 3 (Dữ liệu & FinOps — Phạm Thế Hùng)
# Tự động hóa kiểm tra:
# 1. CloudWatch Observability Dashboard
# 2. CloudWatch Log Groups & Retention = 7 ngày
# 3. CloudWatch Alarms (CPU > 70%, Storage, Billing)
# 4. SNS Alerts Topic & Email Subscriptions
# 5. AWS CloudTrail Audit Trail & S3 Glacier Lifecycle
# 6. Mô phỏng kích hoạt chuông cảnh báo (Trigger Alarm) phục vụ Live Demo
# ==============================================================================

set -e

REGION="${1:-ap-southeast-1}"
PROJECT_NAME="${2:-enterprise-cloud-devsecops}"
ACTION="${3:-all}"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

DASHBOARD_NAME="${PROJECT_NAME}-observability-dashboard"
RDS_ALARM_NAME="${PROJECT_NAME}-rds-cpu-high-alert"
COMPUTE_ALARM="${PROJECT_NAME}-compute-cpu-high-alert"
TRAIL_NAME="${PROJECT_NAME}-audit-trail"
TOPIC_NAME="${PROJECT_NAME}-alerts-topic"

echo -e "${CYAN}======================================================================${NC}"
echo -e "${YELLOW}  ENTERPRISE CLOUD DEVSECOPS — OBSERVABILITY & AUDIT CLI (WEEK 4)     ${NC}"
echo -e "${CYAN}======================================================================${NC}"
echo -e "Region       : ${REGION}"
echo -e "Project Name : ${PROJECT_NAME}"
echo -e "Action       : ${ACTION}\n"

check_dashboard() {
    echo -e "${NC}[1/5] Kiểm tra CloudWatch Observability Dashboard...${NC}"
    if aws cloudwatch get-dashboard --dashboard-name "$DASHBOARD_NAME" --region "$REGION" >/dev/null 2>&1; then
        echo -e "  ${GREEN}[OK] Dashboard tồn tại: ${DASHBOARD_NAME}${NC}"
        echo -e "  ${CYAN}[URL] https://${REGION}.console.aws.amazon.com/cloudwatch/home?region=${REGION}#dashboards:name=${DASHBOARD_NAME}${NC}"
    else
        echo -e "  ${YELLOW}[!] Chưa tìm thấy Dashboard: ${DASHBOARD_NAME}${NC}"
    fi
}

check_log_groups() {
    echo -e "\n${NC}[2/5] Kiểm tra CloudWatch Log Groups & Retention (FinOps = 7 ngày)...${NC}"
    aws logs describe-log-groups --region "$REGION" --query "logGroups[?contains(logGroupName, '${PROJECT_NAME}')].[logGroupName, retentionInDays]" --output table || true
}

check_alarms() {
    echo -e "\n${NC}[3/5] Kiểm tra CloudWatch Alarms (CPU > 70%, Storage, Billing)...${NC}"
    aws cloudwatch describe-alarms --alarm-names "$RDS_ALARM_NAME" "$COMPUTE_ALARM" --region "$REGION" \
        --query "MetricAlarms[*].[AlarmName, StateValue, MetricName, Threshold]" --output table || true
}

check_sns() {
    echo -e "\n${NC}[4/5] Kiểm tra SNS Alerts Topic & Subscriptions...${NC}"
    TOPIC_ARN=$(aws sns list-topics --region "$REGION" --query "Topics[?contains(TopicArn, '${TOPIC_NAME}')].TopicArn" --output text 2>/dev/null || true)
    if [ -n "$TOPIC_ARN" ]; then
        echo -e "  ${GREEN}[OK] Topic ARN: ${TOPIC_ARN}${NC}"
        aws sns list-subscriptions-by-topic --topic-arn "$TOPIC_ARN" --region "$REGION" \
            --query "Subscriptions[*].[Endpoint, SubscriptionArn]" --output table || true
    else
        echo -e "  ${YELLOW}[!] Không tìm thấy SNS Topic ${TOPIC_NAME}${NC}"
    fi
}

check_cloudtrail() {
    echo -e "\n${NC}[5/5] Kiểm tra AWS CloudTrail & S3 Audit Trail...${NC}"
    aws cloudtrail describe-trails --trail-name-list "$TRAIL_NAME" --region "$REGION" \
        --query "trailList[*].[Name, S3BucketName, IsMultiRegionTrail, LogFileValidationEnabled]" --output table || true

    echo -e "\n  Truy vấn 5 sự kiện gọi API gần nhất từ CloudTrail:"
    aws cloudtrail lookup-events --max-results 5 --region "$REGION" \
        --query "Events[*].[EventTime, EventName, Username, EventSource]" --output table || true
}

trigger_alarm() {
    echo -e "\n${YELLOW}🚨 [DEMO MÀN 3] Mô phỏng quá tải CPU 85% trên RDS MySQL...${NC}"
    aws cloudwatch set-alarm-state \
        --alarm-name "$RDS_ALARM_NAME" \
        --state-value ALARM \
        --state-reason "Live Demo: Simulated CPU 85% overload on RDS MySQL - Trigger SNS Email" \
        --region "$REGION"
    echo -e "  ${GREEN}[SUCCESS] Đã gửi thông báo cảnh báo ALARM qua SNS Email!${NC}"
}

reset_alarm() {
    echo -e "\n${GREEN}✅ Đang trả lại trạng thái OK cho Alarm...${NC}"
    aws cloudwatch set-alarm-state \
        --alarm-name "$RDS_ALARM_NAME" \
        --state-value OK \
        --state-reason "Normalized workload under 70% threshold" \
        --region "$REGION"
    echo -e "  ${GREEN}[SUCCESS] Đã trả lại trạng thái OK thành công!${NC}"
}

case "$ACTION" in
    status)
        check_dashboard
        check_log_groups
        check_alarms
        check_sns
        check_cloudtrail
        ;;
    trigger)
        trigger_alarm
        ;;
    reset)
        reset_alarm
        ;;
    all|*)
        check_dashboard
        check_log_groups
        check_alarms
        check_sns
        check_cloudtrail
        echo -e "\n${CYAN}----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}  HƯỚNG DẪN DEMO MÀN 3 (FINOPS & OBSERVABILITY):${NC}"
        echo -e "  - Chạy './test_observability.sh ${REGION} ${PROJECT_NAME} trigger' để bắn email cảnh báo tức thì!"
        echo -e "  - Chạy './test_observability.sh ${REGION} ${PROJECT_NAME} reset' để trả lại trạng thái OK."
        echo -e "${CYAN}----------------------------------------------------------------------${NC}"
        ;;
esac
