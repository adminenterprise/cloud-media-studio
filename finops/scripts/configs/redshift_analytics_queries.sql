-- ==============================================================================
-- AMAZON REDSHIFT SERVERLESS — 7 CÂU TRUY VẤN PHÂN TÍCH KINH DOANH
-- ==============================================================================
-- Dành cho kịch bản bảo vệ đồ án: Chạy lần lượt các query,
-- chụp ảnh kết quả trên Redshift Query Editor v2 làm minh chứng.
-- ==============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 1: DOANH THU THEO THÁNG (Monthly Revenue Trend)
-- Mục đích: Phân tích xu hướng doanh thu theo thời gian
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    DATE_TRUNC('month', sale_date)                          AS sale_month,
    COUNT(DISTINCT sale_id)                                 AS total_orders,
    COUNT(DISTINCT customer_id)                             AS unique_customers,
    SUM(quantity)                                           AS total_items_sold,
    ROUND(SUM(total_amount), 2)                             AS gross_revenue,
    ROUND(SUM(total_amount * discount_pct / 100), 2)        AS total_discount,
    ROUND(SUM(total_amount * (1 - discount_pct / 100)), 2)  AS net_revenue
FROM fact_sales
GROUP BY DATE_TRUNC('month', sale_date)
ORDER BY sale_month;

-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 2: TOP 5 SẢN PHẨM BÁN CHẠY NHẤT (Best-Selling Products)
-- Mục đích: Xác định sản phẩm đóng góp doanh thu lớn nhất
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    p.product_name,
    p.category,
    SUM(s.quantity)                    AS total_qty_sold,
    ROUND(SUM(s.total_amount), 2)     AS total_revenue,
    COUNT(DISTINCT s.customer_id)     AS buyer_count,
    ROUND(AVG(s.total_amount), 2)     AS avg_order_value
FROM fact_sales s
JOIN dim_products p ON s.product_id = p.product_id
GROUP BY p.product_name, p.category
ORDER BY total_revenue DESC
LIMIT 5;

-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 3: DOANH THU THEO DANH MỤC SẢN PHẨM (Revenue by Category)
-- Mục đích: So sánh hiệu suất kinh doanh giữa các danh mục
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    p.category,
    COUNT(DISTINCT s.sale_id)         AS order_count,
    SUM(s.quantity)                   AS items_sold,
    ROUND(SUM(s.total_amount), 2)    AS category_revenue,
    ROUND(
        SUM(s.total_amount) * 100.0 /
        (SELECT SUM(total_amount) FROM fact_sales), 2
    )                                AS revenue_share_pct
FROM fact_sales s
JOIN dim_products p ON s.product_id = p.product_id
GROUP BY p.category
ORDER BY category_revenue DESC;

-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 4: PHÂN TÍCH PHÂN KHÚC KHÁCH HÀNG (Customer Segment Analysis)
-- Mục đích: So sánh hành vi mua hàng giữa Enterprise, SMB, Consumer
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    c.segment,
    COUNT(DISTINCT c.customer_id)     AS customer_count,
    COUNT(s.sale_id)                  AS total_orders,
    ROUND(SUM(s.total_amount), 2)    AS segment_revenue,
    ROUND(AVG(s.total_amount), 2)    AS avg_order_value,
    ROUND(
        SUM(s.total_amount) / COUNT(DISTINCT c.customer_id), 2
    )                                AS revenue_per_customer
FROM fact_sales s
JOIN dim_customers c ON s.customer_id = c.customer_id
GROUP BY c.segment
ORDER BY segment_revenue DESC;

-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 5: DOANH THU THEO VÙNG ĐỊA LÝ (Regional Revenue Breakdown)
-- Mục đích: Phân tích phân bổ doanh thu theo khu vực
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    c.region,
    COUNT(DISTINCT c.customer_id)     AS customer_count,
    COUNT(s.sale_id)                  AS total_orders,
    ROUND(SUM(s.total_amount), 2)    AS region_revenue,
    ROUND(AVG(s.total_amount), 2)    AS avg_order_value
FROM fact_sales s
JOIN dim_customers c ON s.customer_id = c.customer_id
GROUP BY c.region
ORDER BY region_revenue DESC;

-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 6: PHÂN TÍCH PHƯƠNG THỨC THANH TOÁN (Payment Method Analysis)
-- Mục đích: Hiểu tỷ lệ sử dụng của mỗi kênh thanh toán
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    payment_method,
    COUNT(sale_id)                     AS transaction_count,
    ROUND(SUM(total_amount), 2)       AS payment_revenue,
    ROUND(AVG(total_amount), 2)       AS avg_transaction,
    ROUND(
        COUNT(sale_id) * 100.0 /
        (SELECT COUNT(*) FROM fact_sales), 2
    )                                 AS usage_share_pct
FROM fact_sales
GROUP BY payment_method
ORDER BY payment_revenue DESC;

-- ─────────────────────────────────────────────────────────────────────────────
-- QUERY 7: TOP 5 KHÁCH HÀNG GIÁ TRỊ CAO NHẤT (High-Value Customers)
-- Mục đích: Xác định khách hàng VIP theo tổng giá trị mua hàng (CLV)
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    c.customer_name,
    c.segment,
    c.region,
    COUNT(s.sale_id)                   AS total_orders,
    ROUND(SUM(s.total_amount), 2)     AS lifetime_value,
    MIN(s.sale_date)                   AS first_purchase,
    MAX(s.sale_date)                   AS last_purchase,
    DATEDIFF(day, MIN(s.sale_date), MAX(s.sale_date)) AS active_days
FROM fact_sales s
JOIN dim_customers c ON s.customer_id = c.customer_id
GROUP BY c.customer_name, c.segment, c.region
ORDER BY lifetime_value DESC
LIMIT 5;
