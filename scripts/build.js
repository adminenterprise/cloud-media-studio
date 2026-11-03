/**
 * ==============================================================================
 * CLOUD MEDIA STUDIO — FRONTEND BUILD SCRIPT
 * ==============================================================================
 * 1. Thu thập và tối ưu hóa static assets từ frontend/ sang dist/
 * 2. Đảm bảo cấu trúc artifact hợp lệ để chuẩn bị AWS S3 Sync
 * ==============================================================================
 */

const fs = require('fs');
const path = require('path');

const ROOT_DIR = path.resolve(__dirname, '..');
const DIST_DIR = path.join(ROOT_DIR, 'dist');
const FRONTEND_INDEX = path.join(ROOT_DIR, 'frontend', 'index.html');

console.log('🏗️  [Build] Bắt đầu build gói frontend tĩnh cho Cloud Media Studio...');

if (!fs.existsSync(DIST_DIR)) {
  fs.mkdirSync(DIST_DIR, { recursive: true });
}

if (!fs.existsSync(FRONTEND_INDEX)) {
  console.error('❌ Lỗi: Không tìm thấy file frontend/index.html!');
  process.exit(1);
}

// Sao chép index.html sang dist/
fs.copyFileSync(FRONTEND_INDEX, path.join(DIST_DIR, 'index.html'));
const stats = fs.statSync(path.join(DIST_DIR, 'index.html'));

console.log(`✅ [Build] Đã tạo thành công dist/index.html (${(stats.size / 1024).toFixed(1)} KB)`);
console.log('🎉 [Build] Gói artifact dist/ đã sẵn sàng để deploy lên S3 & CloudFront!');

