/**
 * CLOUD MEDIA STUDIO — REALTIME AWS LAMBDA TRIGGER & LOG WATCHER
 */
const { execSync } = require('child_process');

const LOG_GROUP = '/aws/lambda/cloud-media-studio-image-processor';
const S3_BUCKET = 'cloud-media-studio-assets-586643076560';

process.env.PYTHONIOENCODING = 'utf-8';
process.env.PYTHONUTF8 = '1';

async function main() {
  const action = process.argv[2] || 'watch';

  if (action === 'trigger') {
    const filename = 'realtime-trigger-' + Date.now() + '.jpg';
    console.log(`🚀 [1/2] Đang tải file test lên S3: s3://${S3_BUCKET}/uploads/${filename}...`);
    execSync(`aws s3 cp backend/server.js s3://${S3_BUCKET}/uploads/${filename} --region ap-southeast-1`, { stdio: 'inherit' });
    console.log('✅ [1/2] Tải file lên S3 thành công! Đang chờ S3 trigger Lambda xử lý...\n');
    await new Promise(r => setTimeout(r, 3000));
  }

  console.log(`📡 [2/2] Đang đọc logs thời gian thực từ CloudWatch: ${LOG_GROUP}...`);
  const sinceMs = Date.now() - 15 * 60 * 1000;
  const cmd = `aws logs filter-log-events --log-group-name "${LOG_GROUP}" --start-time ${sinceMs} --output json`;
  
  try {
    const raw = execSync(cmd).toString();
    const data = JSON.parse(raw);
    if (!data.events || data.events.length === 0) {
      console.log('Chưa có log mới trong 15 phút qua.');
      return;
    }
    console.log('\n================== CHI TIẾT LOG LAMBDA REALTIME ==================');
    data.events.forEach(e => {
      const time = new Date(e.timestamp).toLocaleTimeString();
      console.log(`[${time}] ${e.message.trim()}`);
    });
    console.log('==================================================================\n');
  } catch (err) {
    console.error('Lỗi khi lấy log:', err.message);
  }
}

main();
