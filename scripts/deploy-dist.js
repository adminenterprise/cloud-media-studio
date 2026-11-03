/**
 * ==============================================================================
 * CLOUD MEDIA STUDIO — STATIC FRONTEND BUILD & DIST FLOW TO CLOUDFRONT / S3
 * ==============================================================================
 * Mục đích:
 * 1. Đóng gói mã nguồn tĩnh frontend (HTML, CSS, JS, Assets) vào thư mục `dist/`
 * 2. Tự động đồng bộ (S3 Sync) lên Amazon S3 Bucket: `cloud-media-studio-assets-586643076560`
 * 3. Áp dụng chuẩn Cache-Control tối ưu:
 *    - HTML (index.html): no-cache, no-store (luôn tải bản mới nhất)
 *    - Static Assets (/assets, .css, .js, .png, .jpg): max-age=31536000 (cache 1 năm tại Edge)
 * 4. Tạo lệnh Invalidation trên CloudFront CDN (Distribution ID: E23QIJLQ2A8EEN)
 * 5. Giúp website tải tức thì (sub-second) từ các PoP Edge toàn cầu mà KHÔNG TỐN TẢI SERVER!
 * ==============================================================================
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const ROOT_DIR = path.resolve(__dirname, '..');
const DIST_DIR = path.join(ROOT_DIR, 'dist');
const FRONTEND_INDEX = path.join(ROOT_DIR, 'frontend', 'index.html');
const S3_BUCKET = 'cloud-media-studio-assets-586643076560';
const CLOUDFRONT_DIST_ID = 'E23QIJLQ2A8EEN';
const CLOUDFRONT_DOMAIN = 'd10b9bys5mn60c.cloudfront.net';

console.log('================================================================');
console.log('🚀 CLOUD MEDIA STUDIO — STATIC DIST & CLOUDFRONT CDN PIPELINE');
console.log('================================================================\n');

// 1. TẠO THƯ MỤC DIST
console.log('📦 [1/4] Chuẩn bị thư mục build `dist/`...');
if (!fs.existsSync(DIST_DIR)) {
  fs.mkdirSync(DIST_DIR, { recursive: true });
}

// 2. COPY CÁC TÀI NGUYÊN TĨNH VÀO DIST
console.log('📄 [2/4] Đóng gói frontend/index.html sang dist/index.html...');
if (fs.existsSync(FRONTEND_INDEX)) {
  fs.copyFileSync(FRONTEND_INDEX, path.join(DIST_DIR, 'index.html'));
  const stats = fs.statSync(path.join(DIST_DIR, 'index.html'));
  console.log(`     ✅ Đã sao chép index.html (${(stats.size / 1024).toFixed(1)} KB) sang dist/`);
} else {
  console.error('     ❌ Không tìm thấy frontend/index.html!');
  process.exit(1);
}

// 3. ĐỒNG BỘ LÊN AMAZON S3
console.log(`\n☁️  [3/4] Tải thư mục dist/ lên S3 Bucket: s3://${S3_BUCKET}...`);
try {
  // Upload index.html với Content-Type text/html và header no-cache
  const uploadIndexCmd = `aws s3 cp "${path.join(DIST_DIR, 'index.html')}" "s3://${S3_BUCKET}/index.html" --content-type "text/html" --cache-control "max-age=0,no-cache,no-store,must-revalidate"`;
  console.log('     > Uploading index.html với no-cache header...');
  execSync(uploadIndexCmd, { stdio: 'inherit' });

  // Sync toàn bộ dist/
  const syncDistCmd = `aws s3 sync "${DIST_DIR}" "s3://${S3_BUCKET}/" --exclude "index.html" --cache-control "public,max-age=31536000,immutable"`;
  execSync(syncDistCmd, { stdio: 'inherit' });
  console.log('     ✅ Đồng bộ S3 thành công!');
} catch (err) {
  console.error('     ❌ Lỗi khi tải lên S3:', err.message);
  process.exit(1);
}

// 4. TẠO CLOUDFRONT CACHE INVALIDATION
console.log(`\n⚡ [4/4] Kích hoạt CloudFront Cache Invalidation (Dist ID: ${CLOUDFRONT_DIST_ID})...`);
try {
  const invalidationCmd = `aws cloudfront create-invalidation --distribution-id ${CLOUDFRONT_DIST_ID} --paths "/*"`;
  const output = execSync(invalidationCmd).toString();
  const parsed = JSON.parse(output);
  console.log(`     ✅ Đã tạo Invalidation ID: ${parsed.Invalidation ? parsed.Invalidation.Id : 'Thành công'}`);
} catch (err) {
  console.warn('     ⚠️ Không thể tạo invalidation tự động:', err.message);
}

console.log('\n================================================================');
console.log('🎉 DEPLOY STATIC DIST THÀNH CÔNG!');
console.log(`🌐 CloudFront CDN URL: https://${CLOUDFRONT_DOMAIN}`);
console.log(`💻 Localhost Server:   http://localhost:3000`);
console.log('================================================================\n');

