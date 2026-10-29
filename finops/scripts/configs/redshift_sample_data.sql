-- ==============================================================================
-- AMAZON REDSHIFT SERVERLESS — DỮ LIỆU MẪU E-COMMERCE & TRUY VẤN PHÂN TÍCH
-- ==============================================================================
-- Phân mảng: Thành viên 3 (Dữ liệu & FinOps — Phạm Thế Hùng)
-- Mục tiêu: Nạp dữ liệu mẫu giao dịch thương mại điện tử, chạy truy vấn
--           phân tích kinh doanh thực tế, chụp ảnh minh chứng cho bảo vệ đồ án.
-- ==============================================================================

-- ===========================
-- PHẦN 1: KHỞI TẠO SCHEMA
-- ===========================

-- Bảng danh mục sản phẩm (Dimension Table)
CREATE TABLE IF NOT EXISTS dim_products (
    product_id    INTEGER PRIMARY KEY,
    product_name  VARCHAR(200) NOT NULL,
    category      VARCHAR(100) NOT NULL,
    unit_price    DECIMAL(10,2) NOT NULL,
    supplier      VARCHAR(150),
    created_at    TIMESTAMP DEFAULT GETDATE()
);

-- Bảng thông tin khách hàng (Dimension Table)
CREATE TABLE IF NOT EXISTS dim_customers (
    customer_id     INTEGER PRIMARY KEY,
    customer_name   VARCHAR(200) NOT NULL,
    email           VARCHAR(200),
    region          VARCHAR(100) NOT NULL,
    segment         VARCHAR(50) NOT NULL,  -- 'Enterprise', 'SMB', 'Consumer'
    registered_at   TIMESTAMP DEFAULT GETDATE()
);

-- Bảng giao dịch bán hàng (Fact Table — Trọng tâm phân tích)
CREATE TABLE IF NOT EXISTS fact_sales (
    sale_id         INTEGER PRIMARY KEY,
    customer_id     INTEGER REFERENCES dim_customers(customer_id),
    product_id      INTEGER REFERENCES dim_products(product_id),
    quantity        INTEGER NOT NULL,
    total_amount    DECIMAL(12,2) NOT NULL,
    discount_pct    DECIMAL(5,2) DEFAULT 0,
    payment_method  VARCHAR(50),
    sale_date       DATE NOT NULL,
    sale_timestamp  TIMESTAMP DEFAULT GETDATE()
);

-- ===========================
-- PHẦN 2: NẠP DỮ LIỆU MẪU
-- ===========================

-- 2A: Sản phẩm mẫu (20 sản phẩm — 4 danh mục)
INSERT INTO dim_products (product_id, product_name, category, unit_price, supplier) VALUES
(1,  'Laptop Dell XPS 15',          'Electronics',   1299.99, 'Dell Technologies'),
(2,  'iPhone 16 Pro Max',           'Electronics',   1199.00, 'Apple Inc.'),
(3,  'Samsung Galaxy S25 Ultra',    'Electronics',    999.99, 'Samsung'),
(4,  'AirPods Pro 3',               'Electronics',    249.00, 'Apple Inc.'),
(5,  'Mechanical Keyboard RGB',     'Electronics',     89.99, 'Logitech'),
(6,  'Áo Polo Nam Premium',         'Fashion',         45.00, 'Uniqlo Vietnam'),
(7,  'Giày Sneaker Classic',        'Fashion',        120.00, 'Nike Vietnam'),
(8,  'Túi Tote Da Thật',            'Fashion',         85.00, 'Local Brand VN'),
(9,  'Quần Jeans Slim Fit',         'Fashion',         55.00, 'Uniqlo Vietnam'),
(10, 'Kính Mát Polarized UV400',    'Fashion',         35.00, 'Ray-Ban'),
(11, 'Cà Phê Rang Xay Đà Lạt 1kg', 'Food & Beverage', 12.50, 'Highlands Coffee'),
(12, 'Trà Oolong Thượng Hạng',     'Food & Beverage',  8.99, 'Phúc Long'),
(13, 'Nước Ép Cam Tươi Organic',    'Food & Beverage',  3.50, 'TH True Juice'),
(14, 'Chocolate Đen 85% Cacao',     'Food & Beverage',  6.99, 'Marou Chocolate'),
(15, 'Mật Ong Rừng Nguyên Chất',    'Food & Beverage', 15.00, 'Bee Farm VN'),
(16, 'Sách "Cloud Computing"',      'Books & Education', 29.99, 'OReilly Media'),
(17, 'Khóa Học AWS Solutions Arch',  'Books & Education', 49.99, 'Udemy'),
(18, 'Sách "Terraform in Action"',  'Books & Education', 39.99, 'Manning'),
(19, 'Khóa Học DevSecOps Pipeline', 'Books & Education', 59.99, 'A Cloud Guru'),
(20, 'Sách "System Design"',        'Books & Education', 34.99, 'Alex Xu');

-- 2B: Khách hàng mẫu (15 khách hàng — 3 phân khúc, 4 vùng)
INSERT INTO dim_customers (customer_id, customer_name, email, region, segment) VALUES
(1,  'Nguyễn Văn An',     'an.nguyen@enterprise.vn',    'Hồ Chí Minh',  'Enterprise'),
(2,  'Trần Thị Bình',     'binh.tran@techcorp.vn',      'Hà Nội',       'Enterprise'),
(3,  'Lê Hoàng Cường',    'cuong.le@startup.io',        'Đà Nẵng',      'SMB'),
(4,  'Phạm Minh Dũng',    'dung.pham@sme.vn',           'Hồ Chí Minh',  'SMB'),
(5,  'Hoàng Thị Ên',      'en.hoang@gmail.com',         'Hà Nội',       'Consumer'),
(6,  'Vũ Đức Phong',      'phong.vu@bigcorp.vn',        'Hồ Chí Minh',  'Enterprise'),
(7,  'Đặng Ngọc Quỳnh',   'quynh.dang@company.vn',      'Cần Thơ',      'SMB'),
(8,  'Bùi Thanh Rồng',    'rong.bui@outlook.com',       'Đà Nẵng',      'Consumer'),
(9,  'Ngô Thị Sương',     'suong.ngo@yahoo.com',        'Hà Nội',       'Consumer'),
(10, 'Cao Văn Tuấn',      'tuan.cao@enterprise.vn',     'Hồ Chí Minh',  'Enterprise'),
(11, 'Mai Thị Uyên',      'uyen.mai@freelancer.vn',     'Đà Nẵng',      'Consumer'),
(12, 'Đinh Quốc Việt',    'viet.dinh@devops.io',        'Hà Nội',       'SMB'),
(13, 'Lý Thị Xuân',       'xuan.ly@retail.vn',          'Cần Thơ',      'SMB'),
(14, 'Trịnh Minh Yên',    'yen.trinh@corp.vn',          'Hồ Chí Minh',  'Enterprise'),
(15, 'Hà Đức Zũng',       'zung.ha@consumer.vn',        'Hà Nội',       'Consumer');

-- 2C: Giao dịch bán hàng mẫu (50 giao dịch — phân bổ đều 6 tháng gần nhất)
INSERT INTO fact_sales (sale_id, customer_id, product_id, quantity, total_amount, discount_pct, payment_method, sale_date) VALUES
-- Tháng 5/2026
(1,  1,  1,  2, 2599.98, 0,    'Credit Card',    '2026-05-03'),
(2,  5,  6,  3,  135.00, 0,    'E-Wallet',       '2026-05-05'),
(3,  3,  11, 5,   62.50, 0,    'Bank Transfer',  '2026-05-08'),
(4,  2,  16, 1,   29.99, 0,    'Credit Card',    '2026-05-12'),
(5,  8,  7,  1,  120.00, 0,    'COD',            '2026-05-15'),
(6,  6,  2,  3, 3597.00, 5.0,  'Credit Card',    '2026-05-18'),
(7,  4,  13, 10,  35.00, 0,    'E-Wallet',       '2026-05-22'),
(8,  9,  10, 2,   70.00, 0,    'E-Wallet',       '2026-05-28'),
-- Tháng 6/2026
(9,  1,  3,  1,  999.99, 0,    'Credit Card',    '2026-06-02'),
(10, 7,  8,  2,  170.00, 0,    'Bank Transfer',  '2026-06-05'),
(11, 10, 17, 5,  249.95, 10.0, 'Credit Card',    '2026-06-08'),
(12, 3,  14, 8,   55.92, 0,    'E-Wallet',       '2026-06-12'),
(13, 5,  9,  2,  110.00, 0,    'COD',            '2026-06-15'),
(14, 12, 19, 3,  179.97, 0,    'Credit Card',    '2026-06-20'),
(15, 11, 4,  1,  249.00, 0,    'E-Wallet',       '2026-06-25'),
(16, 14, 1,  1, 1299.99, 0,    'Bank Transfer',  '2026-06-28'),
-- Tháng 7/2026
(17, 2,  5,  5,  449.95, 5.0,  'Credit Card',    '2026-07-01'),
(18, 6,  20, 2,   69.98, 0,    'E-Wallet',       '2026-07-04'),
(19, 8,  12, 3,   26.97, 0,    'COD',            '2026-07-08'),
(20, 1,  2,  1, 1199.00, 0,    'Credit Card',    '2026-07-12'),
(21, 13, 15, 4,   60.00, 0,    'Bank Transfer',  '2026-07-15'),
(22, 4,  6,  5,  225.00, 10.0, 'E-Wallet',       '2026-07-18'),
(23, 9,  18, 1,   39.99, 0,    'Credit Card',    '2026-07-22'),
(24, 15, 3,  1,  999.99, 0,    'COD',            '2026-07-26'),
-- Tháng 8/2026
(25, 10, 2,  2, 2398.00, 0,    'Credit Card',    '2026-08-02'),
(26, 7,  11, 10, 125.00, 0,    'Bank Transfer',  '2026-08-05'),
(27, 3,  7,  2,  240.00, 5.0,  'E-Wallet',       '2026-08-09'),
(28, 14, 4,  3,  747.00, 0,    'Credit Card',    '2026-08-12'),
(29, 5,  16, 2,   59.98, 0,    'E-Wallet',       '2026-08-16'),
(30, 11, 9,  1,   55.00, 0,    'COD',            '2026-08-20'),
(31, 2,  1,  1, 1299.99, 0,    'Credit Card',    '2026-08-24'),
(32, 6,  13, 20, 70.00, 0,    'Bank Transfer',  '2026-08-28'),
-- Tháng 9/2026
(33, 1,  17, 2,   99.98, 0,    'Credit Card',    '2026-09-01'),
(34, 12, 5,  3,  269.97, 0,    'E-Wallet',       '2026-09-04'),
(35, 4,  14, 6,   41.94, 0,    'COD',            '2026-09-08'),
(36, 8,  19, 1,   59.99, 0,    'Credit Card',    '2026-09-12'),
(37, 15, 8,  1,   85.00, 0,    'Bank Transfer',  '2026-09-15'),
(38, 9,  2,  1, 1199.00, 0,    'Credit Card',    '2026-09-18'),
(39, 13, 6,  4,  180.00, 0,    'E-Wallet',       '2026-09-22'),
(40, 10, 15, 2,   30.00, 0,    'COD',            '2026-09-26'),
(41, 7,  20, 3,  104.97, 0,    'Credit Card',    '2026-09-29'),
-- Tháng 10/2026
(42, 2,  3,  2, 1999.98, 5.0,  'Credit Card',    '2026-10-02'),
(43, 6,  10, 5,  175.00, 0,    'E-Wallet',       '2026-10-05'),
(44, 1,  12, 10,  89.90, 0,    'Bank Transfer',  '2026-10-09'),
(45, 14, 7,  2,  240.00, 0,    'Credit Card',    '2026-10-12'),
(46, 3,  4,  1,  249.00, 0,    'E-Wallet',       '2026-10-15'),
(47, 11, 17, 1,   49.99, 0,    'Credit Card',    '2026-10-18'),
(48, 4,  1,  1, 1299.99, 10.0, 'Bank Transfer',  '2026-10-21'),
(49, 5,  18, 2,   79.98, 0,    'E-Wallet',       '2026-10-24'),
(50, 8,  11, 8,  100.00, 0,    'COD',            '2026-10-27');
