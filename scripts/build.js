/**
 * ==============================================================================
 * CLOUD MEDIA STUDIO — FRONTEND BUILD SCRIPT
 * ==============================================================================
 * 1. Tự động kiểm tra cả frontend/index.html và index.html (thư mục gốc)
 * 2. Lấy phiên bản mới nhất (mới sửa đổi nhất) đưa vào dist/index.html
 * 3. Đồng bộ 2 file để không bao giờ bị lệch dữ liệu
 * ==============================================================================
 */

const fs = require('fs');
const path = require('path');

const ROOT_DIR = path.resolve(__dirname, '..');
const DIST_DIR = path.join(ROOT_DIR, 'dist');
const FRONTEND_INDEX = path.join(ROOT_DIR, 'frontend', 'index.html');
const ROOT_INDEX = path.join(ROOT_DIR, 'index.html');

console.log('🏗️  [Build] Bắt đầu build gói frontend tĩnh cho Cloud Media Studio...');

if (!fs.existsSync(DIST_DIR)) {
  fs.mkdirSync(DIST_DIR, { recursive: true });
}

// Xác định file nào mới hơn giữa frontend/index.html và index.html gốc
let sourceFile = FRONTEND_INDEX;
if (fs.existsSync(FRONTEND_INDEX) && fs.existsSync(ROOT_INDEX)) {
  const feTime = fs.statSync(FRONTEND_INDEX).mtimeMs;
  const rootTime = fs.statSync(ROOT_INDEX).mtimeMs;
  if (rootTime > feTime) {
    sourceFile = ROOT_INDEX;
    console.log('     ℹ️  Phát hiện file index.html ở thư mục gốc mới hơn. Dùng file gốc.');
    fs.copyFileSync(ROOT_INDEX, FRONTEND_INDEX);
  } else {
    sourceFile = FRONTEND_INDEX;
    console.log('     ℹ️  Phát hiện file frontend/index.html mới hơn hoặc bằng. Đồng bộ sang root index.html.');
    fs.copyFileSync(FRONTEND_INDEX, ROOT_INDEX);
  }
} else if (fs.existsSync(ROOT_INDEX)) {
  sourceFile = ROOT_INDEX;
}

if (!fs.existsSync(sourceFile)) {
  console.error('❌ Lỗi: Không tìm thấy file index.html!');
  process.exit(1);
}

// Sao chép sang dist/index.html
fs.copyFileSync(sourceFile, path.join(DIST_DIR, 'index.html'));
const stats = fs.statSync(path.join(DIST_DIR, 'index.html'));

console.log(`✅ [Build] Đã tạo thành công dist/index.html (${(stats.size / 1024).toFixed(1)} KB) từ ${path.relative(ROOT_DIR, sourceFile)}`);
console.log('🎉 [Build] Gói artifact dist/ đã sẵn sàng để deploy lên S3 & CloudFront!');
