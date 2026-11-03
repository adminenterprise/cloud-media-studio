-- ==============================================================================
-- CLOUD MEDIA STUDIO — DATABASE INITIALIZATION SCRIPT (RDS MySQL)
-- Phân mảng: Thành viên 3 (Dữ liệu & FinOps)
-- Chức năng: Lưu trữ Metadata của tài nguyên truyền thông (Media Assets)
-- Tối ưu hóa FinOps: Theo dõi storage_class (S3-Standard vs Glacier)
-- ==============================================================================

CREATE DATABASE IF NOT EXISTS appdb;
USE appdb;

-- ------------------------------------------------------------------------------
-- 1. BẢNG METADATA TÀI NGUYÊN TRUYỀN THÔNG (media_items)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS media_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    format VARCHAR(50) NOT NULL,                  -- 'WebP', 'MP4', 'PNG', 'JPG'
    file_size_mb DECIMAL(5,2) NOT NULL,           -- Kích thước tệp (MB)
    storage_class VARCHAR(50) DEFAULT 'S3-Standard', -- 'S3-Standard' hoặc 'Glacier'
    tags VARCHAR(255) DEFAULT 'Marketing',        -- Thẻ tag phân loại: 'Banner', 'Logo', 'Teaser'
    author VARCHAR(100) DEFAULT 'Creative Team',  -- Tác giả / Người tải lên
    thumbnail_url VARCHAR(500) NULL,              -- Đường dẫn ảnh thumbnail đã resize
    original_url VARCHAR(500) NULL,               -- Đường dẫn file gốc trên S3 Raw Bucket
    dimensions VARCHAR(50) DEFAULT '3840x2160',   -- Độ phân giải gốc (4K, 1080p, etc.)
    status VARCHAR(50) DEFAULT 'READY',           -- 'PROCESSING', 'READY', 'ARCHIVED'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 2. DỮ LIỆU MẪU BAN ĐẦU (SEED DATA CHO BUỔI DEMO HỘI ĐỒNG)
-- ------------------------------------------------------------------------------
INSERT INTO media_items (title, format, file_size_mb, storage_class, tags, author, thumbnail_url, dimensions, status) VALUES
('Brand Identity Logo 2026', 'PNG', 4.20, 'S3-Standard', 'Logo, Branding', 'Member 2 (Dev)', 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=400&q=80', '2048x2048', 'READY'),
('Product Launch Teaser Video', 'MP4', 45.80, 'S3-Standard', 'Teaser, Video, Campaign', 'Member 4 (Sec)', 'https://images.unsplash.com/photo-1574717024653-61fd2cf4d44d?w=400&q=80', '3840x2160', 'READY'),
('Poster Banner Marketing 4K', 'WebP', 12.50, 'S3-Standard', 'Banner, Marketing, 4K', 'Member 1 (Leader)', 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=400&q=80', '3840x2160', 'READY'),
('Archive Event Photo 2025', 'WebP', 8.10, 'Glacier', 'Archive, Event, History', 'Member 3 (FinOps)', 'https://images.unsplash.com/photo-1511578314322-379afb476865?w=400&q=80', '4000x3000', 'ARCHIVED'),
('Social Media Summer Reel', 'MP4', 28.40, 'S3-Standard', 'Reel, Social, Summer', 'Creative Team', 'https://images.unsplash.com/photo-1536240478700-b869070f9279?w=400&q=80', '1080x1920', 'READY'),
('Q3 Financial Infographic 2024', 'WebP', 5.60, 'Glacier', 'Finance, Report, Archive', 'Audit Team', 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=400&q=80', '2400x3600', 'ARCHIVED');

-- ------------------------------------------------------------------------------
-- 3. BẢNG CHỈ SỐ LƯỢT XEM VÀ HÀNG ĐỢI XỬ LÝ (Tương thích DynamoDB Cache)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS media_metrics (
    id INT AUTO_INCREMENT PRIMARY KEY,
    media_id INT NOT NULL,
    views_count INT DEFAULT 0,
    downloads_count INT DEFAULT 0,
    bandwidth_saved_pct INT DEFAULT 84,
    last_accessed TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (media_id) REFERENCES media_items(id) ON DELETE CASCADE
);

INSERT INTO media_metrics (media_id, views_count, downloads_count, bandwidth_saved_pct) VALUES
(1, 1420, 310, 85),
(2, 5890, 892, 78),
(3, 3120, 450, 86),
(4, 210, 15, 92),
(5, 4780, 630, 82),
(6, 120, 8, 90);
