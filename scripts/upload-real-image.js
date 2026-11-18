/**
 * ==============================================================================
 * CLOUD MEDIA STUDIO — CLI TOOL UPLOAD ẢNH THẬT LÊN AMAZON S3 & KÍCH HOẠT LAMBDA
 * ==============================================================================
 * Cách dùng:
 *    node scripts/upload-real-image.js "duong/dan/toi/anh.jpg"
 * ==============================================================================
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const BUCKET = 'cloud-media-studio-assets-586643076560';
const filePath = process.argv[2];

if (!filePath || !fs.existsSync(filePath)) {
  console.log('⚠️  Chưa truyền đường dẫn ảnh hoặc file không tồn tại!');
  console.log('👉 Cách dùng: node scripts/upload-real-image.js "ten_anh.jpg"');
  process.exit(1);
}

const stats = fs.statSync(filePath);
const filename = path.basename(filePath);
const ext = path.extname(filePath).toLowerCase();
const mimeMap = {
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.webp': 'image/webp',
  '.gif': 'image/gif',
  '.mp4': 'video/mp4'
};
const contentType = mimeMap[ext] || 'application/octet-stream';

console.log('================================================================');
console.log('🚀 CLOUD MEDIA STUDIO — TẢI ẢNH THẬT LÊN S3 & KÍCH HOẠT LAMBDA');
console.log(`📁 File nguồn:     ${filePath} (${(stats.size / 1024).toFixed(1)} KB)`);
console.log(`🪣 Bucket S3:      s3://${BUCKET}/uploads/${filename}`);
console.log(`🏷️  Content-Type:   ${contentType}`);
console.log('================================================================\n');

const s3Key = `uploads/${filename}`;
const cmd = `aws s3 cp "${filePath}" "s3://${BUCKET}/${s3Key}" --content-type "${contentType}" --region ap-southeast-1`;

try {
  execSync(cmd, { stdio: 'inherit' });
  console.log('\n================================================================');
  console.log('🎉 TẢI ẢNH THẬT THÀNH CÔNG!');
  console.log(`🪣 S3 URI:        s3://${BUCKET}/${s3Key}`);
  console.log(`🌐 CloudFront CDN: https://d10b9bys5mn60c.cloudfront.net/${s3Key}`);
  console.log('⚡ S3 đã tự động kích hoạt Lambda: cloud-media-studio-image-processor');
  console.log('================================================================\n');
} catch (err) {
  console.error('❌ Lỗi tải lên S3:', err.message);
}

