/**
 * ==============================================================================
 * CLOUD MEDIA STUDIO — NATIVE RATE LIMIT LOAD TESTER
 * ==============================================================================
 * Mục đích: Kiểm tra cơ chế Rate Limiting mà không cần cài thêm binary k6
 * Cách chạy:
 *    node tests/run-rate-limit-test.js
 * ==============================================================================
 */

const http = require('http');
const https = require('https');

const TARGET_URL = process.env.TARGET_URL || 'https://jtkvl7zyutkt34p3m5g3ui76ge0mehbp.lambda-url.ap-southeast-1.on.aws/api/info';
const TOTAL_REQUESTS = Number(process.env.TOTAL_REQUESTS || 125); // Gửi 125 request liên tiếp (ngưỡng giới hạn AWS Lambda API là 100 req / 60s)
const CONCURRENCY = Number(process.env.CONCURRENCY || 1); // Giữ 1 luồng keep-alive để đảm bảo bắn đúng 1 Lambda container ấm

const isHttps = TARGET_URL.startsWith('https://');
const client = isHttps ? https : http;
const agent = isHttps
  ? new https.Agent({ keepAlive: true, maxSockets: CONCURRENCY })
  : new http.Agent({ keepAlive: true, maxSockets: CONCURRENCY });

console.log('================================================================');
console.log('⚡ CLOUD MEDIA STUDIO — BẮT ĐẦU LOAD TEST KIỂM TRA RATE LIMIT (LIVE AWS)');
console.log(`🎯 Mục tiêu: ${TARGET_URL}`);
console.log(`📦 Tổng request: ${TOTAL_REQUESTS} | Đồng thời: ${CONCURRENCY} worker (Keep-Alive)`);
console.log('🛡️ Ngưỡng Rate Limiting: 100 requests / 60 giây / IP');
console.log('================================================================\n');

let completed = 0;
let statusCounts = {};
let latencies = [];

function makeRequest(index) {
  return new Promise((resolve) => {
    const start = Date.now();
    const req = client.get(TARGET_URL, { agent }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        const duration = Date.now() - start;
        latencies.push(duration);
        statusCounts[res.statusCode] = (statusCounts[res.statusCode] || 0) + 1;
        completed++;

        const icon = res.statusCode === 200 ? '✅ 200 OK' : (res.statusCode === 429 ? '🛑 429 RATE LIMITED' : `⚠️ ${res.statusCode}`);
        if (completed <= 5 || completed % 20 === 0 || (res.statusCode === 429 && (statusCounts[429] <= 5 || completed === TOTAL_REQUESTS))) {
          console.log(`  [Req #${String(index).padStart(3, '0')}] ${icon} (${duration}ms)`);
        }
        resolve();
      });
    });

    req.on('error', (err) => {
      statusCounts['ERROR'] = (statusCounts['ERROR'] || 0) + 1;
      completed++;
      console.error(`  [Req #${index}] ❌ Lỗi kết nối:`, err.message);
      resolve();
    });
  });
}

async function run() {
  const startTime = Date.now();

  // Chạy các request theo lô đồng thời
  for (let i = 1; i <= TOTAL_REQUESTS; i += CONCURRENCY) {
    const batch = [];
    for (let j = 0; j < CONCURRENCY && (i + j) <= TOTAL_REQUESTS; j++) {
      batch.push(makeRequest(i + j));
    }
    await Promise.all(batch);
  }

  const totalTime = Date.now() - startTime;
  const avgLatency = (latencies.reduce((a, b) => a + b, 0) / latencies.length).toFixed(1);

  console.log('\n================================================================');
  console.log('📊 KẾT QUẢ LOAD TEST RATE LIMITING:');
  console.log(`⏱️ Tổng thời gian: ${totalTime}ms | Độ trễ trung bình: ${avgLatency}ms`);
  console.log('📈 Thống kê mã phản hồi HTTP:');
  for (const [code, count] of Object.entries(statusCounts)) {
    const pct = ((count / TOTAL_REQUESTS) * 100).toFixed(1);
    if (code === '200') {
      console.log(`   🟢 HTTP 200 (Thành công):     ${count} requests (${pct}%)`);
    } else if (code === '429') {
      console.log(`   🔴 HTTP 429 (Bị chặn Rate Limit): ${count} requests (${pct}%)`);
    } else if (code === '403') {
      console.log(`   🛡️ HTTP 403 (WAF Blocked):        ${count} requests (${pct}%)`);
    } else {
      console.log(`   ⚪ HTTP ${code}:                   ${count} requests (${pct}%)`);
    }
  }

  if (statusCounts['429'] || statusCounts['403']) {
    console.log('\n🎉 KẾT LUẬN: CƠ CHẾ BẢO VỆ RATE LIMITING HOẠT ĐỘNG HOÀN HẢO!');
  } else {
    console.log('\n⚠️ Chưa chạm ngưỡng Rate Limit. Hãy thử tăng số lượng request.');
  }
  console.log('================================================================\n');
}

run();

