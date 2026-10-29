#!/usr/bin/env bash
# ==============================================================================
# ENTERPRISE CLOUD DEVSECOPS — REDSHIFT SERVERLESS DEMO LIFECYCLE (TUẦN 5)
# ==============================================================================
# Phân mảng: Thành viên 3 (Dữ liệu & FinOps — Phạm Thế Hùng)
# Tự động hóa: Deploy → Load Data → Run Analytics → Screenshot → Destroy
# ⚠️  CẢNH BÁO FINOPS: ~$3/giờ (8 RPU). BẮT BUỘC XÓA SAU DEMO!
# ==============================================================================

set -euo pipefail

REGION="${1:-ap-southeast-1}"
PROJECT_NAME="${2:-enterprise-cloud-devsecops}"
ACTION="${3:-fulldemo}"

NAMESPACE="${PROJECT_NAME}-analytics-ns"
WORKGROUP="${PROJECT_NAME}-analytics-wg"
DB_NAME="analytics_db"
SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIGS_DIR="${SCRIPTS_DIR}/configs"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${CYAN}======================================================================${NC}"
echo -e "${YELLOW}  ENTERPRISE CLOUD — REDSHIFT SERVERLESS DEMO (WEEK 5)               ${NC}"
echo -e "${CYAN}======================================================================${NC}"
echo -e "Region    : ${REGION}"
echo -e "Namespace : ${NAMESPACE}"
echo -e "Workgroup : ${WORKGROUP}"
echo -e "Action    : ${ACTION}\n"

wait_workgroup() {
    echo -e "${YELLOW}[...] Waiting for workgroup to become AVAILABLE (up to 10 min)...${NC}"
    local elapsed=0
    while [ $elapsed -lt 600 ]; do
        STATUS=$(aws redshift-serverless get-workgroup --workgroup-name "$WORKGROUP" --region "$REGION" \
            --query "workgroup.status" --output text 2>/dev/null || echo "CREATING")
        if [ "$STATUS" = "AVAILABLE" ]; then
            echo -e "${GREEN}[OK] Workgroup AVAILABLE!${NC}"
            ENDPOINT=$(aws redshift-serverless get-workgroup --workgroup-name "$WORKGROUP" --region "$REGION" \
                --query "workgroup.endpoint.address" --output text)
            echo -e "${CYAN}     Endpoint: ${ENDPOINT}:5439${NC}"
            return 0
        fi
        echo "     Status: $STATUS (${elapsed}s)..."
        sleep 15
        elapsed=$((elapsed + 15))
    done
    echo -e "${RED}[TIMEOUT] Workgroup not ready after 600s!${NC}"
    return 1
}

run_sql() {
    local sql="$1"
    local desc="$2"
    echo -e "\n    → Executing: ${desc}..."
    STMT_ID=$(aws redshift-data execute-statement \
        --workgroup-name "$WORKGROUP" --database "$DB_NAME" \
        --sql "$sql" --region "$REGION" --query "Id" --output text)
    # Wait for completion
    local elapsed=0
    while [ $elapsed -lt 120 ]; do
        sleep 3; elapsed=$((elapsed + 3))
        STMT_STATUS=$(aws redshift-data describe-statement --id "$STMT_ID" --region "$REGION" \
            --query "Status" --output text)
        if [ "$STMT_STATUS" = "FINISHED" ]; then
            echo -e "      ${GREEN}[OK] Completed${NC}"
            return 0
        elif [ "$STMT_STATUS" = "FAILED" ]; then
            ERR=$(aws redshift-data describe-statement --id "$STMT_ID" --region "$REGION" \
                --query "Error" --output text)
            echo -e "      ${RED}[FAIL] $ERR${NC}"
            return 1
        fi
    done
    echo -e "      ${YELLOW}[TIMEOUT]${NC}"
    return 1
}

deploy_redshift() {
    echo -e "\n${YELLOW}[1/4] ⚡ Deploying Redshift Serverless via Terraform...${NC}"
    echo -e "${RED}       ⚠️  COST: ~\$3.00/hr (8 RPU). DELETE AFTER 2 HOURS MAX!${NC}"
    pushd "${SCRIPTS_DIR}/../terraform" > /dev/null
    terraform apply -auto-approve -var="enable_redshift_demo=true"
    popd > /dev/null
    wait_workgroup
}

load_data() {
    echo -e "\n${YELLOW}[2/4] 📥 Loading sample e-commerce data...${NC}"
    local sql_file="${CONFIGS_DIR}/redshift_sample_data.sql"
    if [ ! -f "$sql_file" ]; then
        echo -e "${RED}    [!] File not found: $sql_file${NC}"
        return 1
    fi

    # Read and split SQL file into statements (skip comments)
    local stmt=""
    local count=0
    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*-- ]] && continue
        [[ -z "${line// /}" ]] && continue
        stmt+="$line "
        if [[ "$line" =~ \;[[:space:]]*$ ]]; then
            stmt="${stmt%;*}"
            if [ ${#stmt} -gt 10 ]; then
                count=$((count + 1))
                run_sql "$stmt" "Statement $count"
            fi
            stmt=""
        fi
    done < "$sql_file"
    echo -e "\n    ${GREEN}[OK] Sample data loaded!${NC}"
}

run_queries() {
    echo -e "\n${YELLOW}[3/4] 📊 Running 7 analytics queries...${NC}"
    echo -e "${CYAN}       📸 Screenshot each result for evidence!${NC}"

    local queries=(
        "SELECT DATE_TRUNC('month', sale_date) AS month, COUNT(*) AS orders, ROUND(SUM(total_amount),2) AS revenue FROM fact_sales GROUP BY 1 ORDER BY 1"
        "SELECT p.product_name, p.category, SUM(s.quantity) AS qty, ROUND(SUM(s.total_amount),2) AS revenue FROM fact_sales s JOIN dim_products p ON s.product_id=p.product_id GROUP BY 1,2 ORDER BY revenue DESC LIMIT 5"
        "SELECT p.category, COUNT(*) AS orders, ROUND(SUM(s.total_amount),2) AS revenue FROM fact_sales s JOIN dim_products p ON s.product_id=p.product_id GROUP BY 1 ORDER BY revenue DESC"
        "SELECT c.segment, COUNT(DISTINCT c.customer_id) AS customers, ROUND(SUM(s.total_amount),2) AS revenue, ROUND(AVG(s.total_amount),2) AS avg_order FROM fact_sales s JOIN dim_customers c ON s.customer_id=c.customer_id GROUP BY 1 ORDER BY revenue DESC"
        "SELECT c.region, COUNT(*) AS orders, ROUND(SUM(s.total_amount),2) AS revenue FROM fact_sales s JOIN dim_customers c ON s.customer_id=c.customer_id GROUP BY 1 ORDER BY revenue DESC"
        "SELECT payment_method, COUNT(*) AS txns, ROUND(SUM(total_amount),2) AS revenue FROM fact_sales GROUP BY 1 ORDER BY revenue DESC"
        "SELECT c.customer_name, c.segment, ROUND(SUM(s.total_amount),2) AS lifetime_value FROM fact_sales s JOIN dim_customers c ON s.customer_id=c.customer_id GROUP BY 1,2 ORDER BY lifetime_value DESC LIMIT 5"
    )
    local names=(
        "QUERY 1: Monthly Revenue Trend"
        "QUERY 2: Top 5 Best-Selling Products"
        "QUERY 3: Revenue by Category"
        "QUERY 4: Customer Segment Analysis"
        "QUERY 5: Regional Revenue Breakdown"
        "QUERY 6: Payment Method Analysis"
        "QUERY 7: Top 5 High-Value Customers"
    )

    for i in "${!queries[@]}"; do
        echo -e "\n    ${CYAN}═══════════════════════════════════════════${NC}"
        echo -e "    ${YELLOW}${names[$i]}${NC}"
        echo -e "    ${CYAN}═══════════════════════════════════════════${NC}"
        run_sql "${queries[$i]}" "${names[$i]}"
        # Show results
        aws redshift-data get-statement-result --id "$STMT_ID" --region "$REGION" \
            --query "Records[*]" --output table 2>/dev/null || true
    done
    echo -e "\n    ${GREEN}[OK] All 7 analytics queries completed!${NC}"
}

destroy_redshift() {
    echo -e "\n${RED}[4/4] 🗑️  DESTROYING Redshift Serverless (FinOps credit protection)...${NC}"
    pushd "${SCRIPTS_DIR}/../terraform" > /dev/null
    terraform apply -auto-approve -var="enable_redshift_demo=false"
    popd > /dev/null
    echo -e "\n    ${GREEN}[OK] Redshift Serverless DESTROYED! \$200 credit protected.${NC}"
}

check_status() {
    echo -e "\n[STATUS] Checking Redshift Serverless status..."
    aws redshift-serverless get-namespace --namespace-name "$NAMESPACE" --region "$REGION" \
        --query "namespace.[namespaceName, status, dbName]" --output table 2>/dev/null \
        || echo -e "    Namespace: NOT FOUND"
    aws redshift-serverless get-workgroup --workgroup-name "$WORKGROUP" --region "$REGION" \
        --query "workgroup.[workgroupName, status, baseCapacity, endpoint.address]" --output table 2>/dev/null \
        || echo -e "    Workgroup: NOT FOUND"
}

case "$ACTION" in
    deploy)    deploy_redshift ;;
    loaddata)  load_data ;;
    queries)   run_queries ;;
    status)    check_status ;;
    destroy)   destroy_redshift ;;
    fulldemo|*)
        echo -e "${YELLOW}🚀 FULL DEMO LIFECYCLE: Deploy → Load → Query → Destroy${NC}"
        echo -e "${CYAN}⏱️  Estimated: 15-20 min | Cost: ~\$0.50-\$1.00 USD${NC}\n"
        deploy_redshift
        load_data
        run_queries
        echo -e "\n${CYAN}══════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}  📸  TIME TO SCREENSHOT! Open AWS Console → Redshift     ${NC}"
        echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
        echo -e "  Press Enter after screenshots to DESTROY resources..."
        read -r
        destroy_redshift
        echo -e "\n${GREEN}  ✅  WEEK 5 DEMO COMPLETE! CREDIT PROTECTED!${NC}"
        ;;
esac
