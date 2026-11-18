/**
 * ==============================================================================
 * CLOUD MEDIA STUDIO — REAL SERVERLESS WEBP & THUMBNAIL ENGINE (AWS LAMBDA ARM64)
 * ==============================================================================
 * - Tự động kích hoạt bởi sự kiện S3 ObjectCreated (prefix: uploads/)
 * - Tải file ảnh nhị phân gốc từ S3, dùng thư viện `sharp` trên chip Graviton2 ARM64:
 *   1. Nén ảnh sang định dạng chuẩn WebP -> lưu thật vào `processed/<name>.webp`
 *   2. Cắt 3 ảnh Thumbnail WebP thật -> lưu vào `thumbnails/{mobile,tablet,desktop}/`
 * ==============================================================================
 */

const { S3Client, GetObjectCommand, PutObjectCommand } = require('@aws-sdk/client-s3');
const sharp = require('sharp');

const s3 = new S3Client({ region: process.env.AWS_REGION || 'ap-southeast-1' });
const IMAGE_EXT_REGEX = /\.(jpe?g|png|webp|gif|avif|tiff|bmp)$/i;

async function streamToBuffer(stream) {
  const chunks = [];
  for await (const chunk of stream) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
  }
  return Buffer.concat(chunks);
}

exports.handler = async (event) => {
  console.log('[Lambda:ImageProcessor] Nhận sự kiện S3:', JSON.stringify(event));

  const records = event.Records || [];
  const results = [];

  for (const record of records) {
    const eventName = record.eventName || '';
    if (eventName.includes('Copy')) {
      console.log(`[Skip] Bỏ qua sự kiện sao chép đổi lớp lưu trữ (${eventName}).`);
      continue;
    }

    const bucket = record.s3?.bucket?.name || 'cloud-media-studio-assets-586643076560';
    const rawKey = record.s3?.object?.key || '';
    const srcKey = decodeURIComponent(rawKey.replace(/\+/g, ' '));

    // Chốt chặn chống vòng lặp vô hạn: Chỉ xử lý file nằm trong thư mục uploads/
    if (!srcKey.startsWith('uploads/') || srcKey === 'uploads/') {
      console.log(`[Skip] Bỏ qua đối tượng ngoài vùng uploads/: ${srcKey}`);
      continue;
    }

    const filename = srcKey.substring(srcKey.lastIndexOf('/') + 1);
    if (!IMAGE_EXT_REGEX.test(filename)) {
      console.log(`[Skip] Tệp "${filename}" không phải định dạng ảnh tĩnh, ghi nhận metadata.`);
      results.push({ status: 'SKIPPED_NON_IMAGE', file: srcKey });
      continue;
    }

    try {
      // 1. Tải luồng nhị phân ảnh gốc từ S3
      const getRes = await s3.send(new GetObjectCommand({ Bucket: bucket, Key: srcKey }));
      const inputBuffer = await streamToBuffer(getRes.Body);
      const originalBytes = inputBuffer.length;

      // 2. Đọc thông số ảnh gốc bằng sharp
      const meta = await sharp(inputBuffer).metadata();
      const origWidth = meta.width || 0;
      const origHeight = meta.height || 0;
      const baseName = filename.replace(/\.[^/.]+$/, '');

      console.log(
        `[Processing] File gốc: s3://${bucket}/${srcKey} | Kích thước: ${origWidth}x${origHeight} | Dung lượng: ${(originalBytes / 1024).toFixed(1)} KB`
      );

      // 3. Nén bản chính sang chuẩn WebP chất lượng cao
      const webpBuffer = await sharp(inputBuffer)
        .rotate()
        .webp({ quality: 80, effort: 4 })
        .toBuffer();

      const webpBytes = webpBuffer.length;
      const savingsPct = originalBytes > 0
        ? Math.round(((originalBytes - webpBytes) / originalBytes) * 1000) / 10
        : 0;
      const processedKey = `processed/${baseName}.webp`;

      // 4. Tạo 3 phiên bản Thumbnail thực tế (Mobile 320w, Tablet 768w, Desktop 1200w)
      const thumbConfigs = [
        { label: 'mobile', width: 320, key: `thumbnails/mobile/${baseName}_320.webp` },
        { label: 'tablet', width: 768, key: `thumbnails/tablet/${baseName}_768.webp` },
        { label: 'desktop', width: 1200, key: `thumbnails/desktop/${baseName}_1200.webp` }
      ];

      const thumbOutputs = await Promise.all(
        thumbConfigs.map(async (cfg) => {
          const buf = await sharp(inputBuffer)
            .rotate()
            .resize({ width: cfg.width, withoutEnlargement: true })
            .webp({ quality: 78 })
            .toBuffer();

          await s3.send(
            new PutObjectCommand({
              Bucket: bucket,
              Key: cfg.key,
              Body: buf,
              ContentType: 'image/webp',
              CacheControl: 'public,max-age=31536000'
            })
          );

          return {
            target: cfg.label,
            width: cfg.width,
            key: cfg.key,
            sizeBytes: buf.length,
            sizeKb: Math.round((buf.length / 1024) * 10) / 10
          };
        })
      );

      // 5. Ghi file WebP chính vào processed/ kèm Metadata đối chiếu
      await s3.send(
        new PutObjectCommand({
          Bucket: bucket,
          Key: processedKey,
          Body: webpBuffer,
          ContentType: 'image/webp',
          CacheControl: 'public,max-age=31536000',
          Metadata: {
            'original-key': encodeURIComponent(srcKey),
            'original-bytes': String(originalBytes),
            'webp-bytes': String(webpBytes),
            'savings-pct': String(savingsPct),
            'dimensions': `${origWidth}x${origHeight}`
          }
        })
      );

      console.log(
        `[Success] Đã ghi thật lên S3: ${processedKey} (${(webpBytes / 1024).toFixed(1)} KB, giảm ${savingsPct}%) + 3 Thumbnails!`
      );

      results.push({
        status: 'SUCCESS',
        originalKey: srcKey,
        processedKey,
        dimensions: `${origWidth}x${origHeight}`,
        originalBytes,
        webpBytes,
        savingsPct,
        thumbnails: thumbOutputs
      });
    } catch (err) {
      console.error(`[Error] Lỗi khi xử lý ảnh ${srcKey}:`, err);
      results.push({ status: 'ERROR', file: srcKey, error: err.message });
    }
  }

  return {
    statusCode: 200,
    body: JSON.stringify({
      message: 'Real WebP & Thumbnail S3 Pipeline executed',
      processedCount: results.length,
      results
    })
  };
};
