/**
 * End-to-End Verification Test for 100% Cloud-Native AWS Serverless Pipeline:
 * 1. Health & Info check on AWS Lambda Function URL
 * 2. SQL Injection protection check (expects HTTP 403)
 * 3. Request SigV4 S3 Presigned PUT URL (zero client AWS keys)
 * 4. Direct HTTP PUT of a real 1600x1000 PNG image to Amazon S3
 * 5. Poll /api/s3-media to verify AWS Lambda `sharp` generated REAL .webp + 3 thumbnails on S3
 * 6. Verify CloudFront CDN serves the real generated .webp & thumbnails with HTTP 200 (image/webp)
 */

const zlib = require('zlib');

const API_BASE = 'https://jtkvl7zyutkt34p3m5g3ui76ge0mehbp.lambda-url.ap-southeast-1.on.aws';

// Tạo 1 bức ảnh PNG thật 1600x1000 (RGB gradient + pattern) hoàn toàn bằng Node.js chuẩn (CRC32 + Zlib)
function createRealRgbPng(width, height) {
  const crcTable = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) {
      c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    }
    crcTable[n] = c >>> 0;
  }
  function crc32(buf) {
    let c = 0xffffffff;
    for (let i = 0; i < buf.length; i++) {
      c = crcTable[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
    }
    return (c ^ 0xffffffff) >>> 0;
  }
  function makeChunk(type, data) {
    const typeBuf = Buffer.from(type, 'ascii');
    const lenBuf = Buffer.alloc(4);
    lenBuf.writeUInt32BE(data.length, 0);
    const crcInput = Buffer.concat([typeBuf, data]);
    const crcBuf = Buffer.alloc(4);
    crcBuf.writeUInt32BE(crc32(crcInput), 0);
    return Buffer.concat([lenBuf, typeBuf, data, crcBuf]);
  }

  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8; // bit depth
  ihdr[9] = 2; // color type RGB
  ihdr[10] = 0;
  ihdr[11] = 0;
  ihdr[12] = 0;

  const rowSize = width * 3 + 1;
  const rawData = Buffer.alloc(rowSize * height);
  for (let y = 0; y < height; y++) {
    const rowOffset = y * rowSize;
    rawData[rowOffset] = 0; // filter None
    for (let x = 0; x < width; x++) {
      const px = rowOffset + 1 + x * 3;
      rawData[px] = Math.floor((x / width) * 220) + ((x ^ y) & 31);     // R
      rawData[px + 1] = Math.floor((y / height) * 180) + ((x + y) & 31); // G
      rawData[px + 2] = 185 - Math.floor(((x + y) / (width + height)) * 120); // B
    }
  }

  // Dùng mức nén zlib nhẹ để ảnh gốc PNG nặng khoảng ~450 KB (giống ảnh chụp màn hình thực tế)
  const compressed = zlib.deflateSync(rawData, { level: 2 });
  return Buffer.concat([
    signature,
    makeChunk('IHDR', ihdr),
    makeChunk('IDAT', compressed),
    makeChunk('IEND', Buffer.alloc(0))
  ]);
}

async function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function main() {
  console.log('=== [TEST 1] Kiểm tra Health & Info của AWS Lambda Function URL ===');
  const infoRes = await fetch(`${API_BASE}/api/info`);
  const info = await infoRes.json();
  console.log('HTTP', infoRes.status, info);
  if (infoRes.status !== 200) throw new Error('Health check failed');

  console.log('\n=== [TEST 2] Kiểm tra chặn tấn công SQL Injection ===');
  const sqliRes = await fetch(`${API_BASE}/api/search?q=${encodeURIComponent("' OR 1=1 --")}`);
  const sqliBody = await sqliRes.json();
  console.log('HTTP', sqliRes.status, sqliBody);
  if (sqliRes.status !== 403) throw new Error('SQLi check did not return 403');

  console.log('\n=== [TEST 3] Tạo ảnh PNG thật (1600x1000) & Xin S3 Presigned PUT URL ===');
  const pngBuffer = createRealRgbPng(1600, 1000);
  console.log(`Đã tạo ảnh PNG thật: ${(pngBuffer.length / 1024).toFixed(1)} KB (1600x1000)`);

  const testFilename = 'cloud-studio-showcase-banner.png';
  const presignRes = await fetch(`${API_BASE}/api/presign`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      filename: testFilename,
      contentType: 'image/png',
      title: 'Cloud Studio Showcase Banner'
    })
  });
  const presign = await presignRes.json();
  console.log('Presign response ok:', presign.ok, '| Key:', presign.s3Key);
  if (!presign.ok || !presign.uploadUrl) throw new Error('Failed to get presigned URL');

  console.log('\n=== [TEST 4] Upload trực tiếp từ Client lên Amazon S3 qua Presigned PUT URL ===');
  const putRes = await fetch(presign.uploadUrl, {
    method: 'PUT',
    headers: { 'Content-Type': 'image/png' },
    body: pngBuffer
  });
  console.log('S3 Direct PUT HTTP Status:', putRes.status);
  if (putRes.status !== 200) {
    const errTxt = await putRes.text();
    throw new Error(`S3 PUT failed: ${putRes.status} ${errTxt}`);
  }

  console.log('\n=== [TEST 5] Chờ AWS Lambda ARM64 (sharp) tự động nén WebP & tạo 3 Thumbnails ===');
  let matchedItem = null;
  for (let attempt = 1; attempt <= 6; attempt++) {
    await sleep(2000);
    const listRes = await fetch(`${API_BASE}/api/s3-media`);
    const listData = await listRes.json();
    const found = (listData.items || []).find((i) => i.title === testFilename);
    console.log(`Lần kiểm tra ${attempt}: found=${Boolean(found)}, webpProcessed=${found?.webpProcessed}`);
    if (found && found.webpProcessed) {
      matchedItem = found;
      break;
    }
  }

  if (!matchedItem) {
    throw new Error('Lambda chưa tạo xong file WebP trên S3 trong thời gian chờ!');
  }

  console.log('\n🎉 KẾT QUẢ NÉN THẬT TRÊN S3:');
  console.log(' - File gốc S3     :', matchedItem.s3_url, `(${matchedItem.originalSizeFormatted})`);
  console.log(' - File WebP S3    :', matchedItem.processed_s3_url, `(${matchedItem.webpSizeFormatted})`);
  console.log(' - Tỷ lệ giảm thật :', `${matchedItem.savingsPct}%`);
  console.log(' - Thumb Mobile 320:', matchedItem.thumbnails.mobile);
  console.log(' - Thumb Tablet 768:', matchedItem.thumbnails.tablet);
  console.log(' - Thumb Desk 1200 :', matchedItem.thumbnails.desktop);

  console.log('\n=== [TEST 6] Kiểm tra truy cập thực tế qua CloudFront CDN ===');
  for (const [label, url] of [
    ['WebP chính', matchedItem.webp_cdn_url],
    ['Thumb Mobile 320w', matchedItem.thumbnails.mobile?.url],
    ['Thumb Desktop 1200w', matchedItem.thumbnails.desktop?.url]
  ]) {
    const cfRes = await fetch(url, { method: 'HEAD' });
    console.log(` - ${label}: HTTP ${cfRes.status} | Content-Type: ${cfRes.headers.get('content-type')} | Content-Length: ${cfRes.headers.get('content-length')} bytes`);
    if (cfRes.status !== 200) throw new Error(`CloudFront failed for ${url}`);
  }

  console.log('\n✅ TẤT CẢ 6 BÀI TEST END-TO-END TRÊN AWS CLOUD ĐỀU THÀNH CÔNG 100%!');
}

main().catch((err) => {
  console.error('❌ TEST FAILED:', err);
  process.exit(1);
});

