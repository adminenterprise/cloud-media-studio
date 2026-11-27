/**
 * ==============================================================================
 * CLOUD MEDIA STUDIO — 100% CLOUD-NATIVE SERVERLESS API (AWS LAMBDA FUNCTION URL)
 * ==============================================================================
 * Chức năng:
 * 1. POST /api/presign    : Cấp phát S3 Presigned PUT URL (SigV4) tải thẳng lên S3
 * 2. GET  /api/s3-media   : Đọc danh sách file thật trên S3 (uploads, processed WebP, 3 thumbnails)
 * 3. POST /api/s3-archive : Chuyển lớp lưu trữ thật trên S3 sang GLACIER_IR (FinOps)
 * 4. POST /api/s3-delete  : Xóa đồng bộ file gốc + bản WebP + thumbnails trên S3
 * 5. GET  /api/search     : Tìm kiếm kho Media tích hợp lớp chặn SQLi / XSS (403 Forbidden)
 * 6. Bảo vệ Rate Limiting : Giới hạn tốc độ yêu cầu theo IP chống Spam / DDoS (429)
 * ==============================================================================
 */

const crypto = require('crypto');
const os = require('os');
const {
  S3Client,
  ListObjectsV2Command,
  CopyObjectCommand,
  DeleteObjectsCommand
} = require('@aws-sdk/client-s3');

const REGION = process.env.AWS_REGION || 'ap-southeast-1';
const BUCKET = process.env.ASSETS_BUCKET || 'cloud-media-studio-assets-586643076560';
const CDN_DOMAIN = process.env.CDN_DOMAIN || 'https://cloudmedia.duccloud.men';

const s3 = new S3Client({ region: REGION });

// Bộ đếm Rate Limit theo IP ngay trong bộ nhớ thực thi của Lambda Container
const rateMap = new Map();
const RATE_WINDOW_MS = 60 * 1000;
const RATE_MAX_REQ = 100;

function checkRateLimit(ip) {
  const now = Date.now();
  let entry = rateMap.get(ip);
  if (!entry || now - entry.start > RATE_WINDOW_MS) {
    entry = { count: 1, start: now };
    rateMap.set(ip, entry);
    return { allowed: true, remaining: RATE_MAX_REQ - 1 };
  }
  entry.count += 1;
  return {
    allowed: entry.count <= RATE_MAX_REQ,
    remaining: Math.max(0, RATE_MAX_REQ - entry.count)
  };
}

// Chữ ký nhận diện tấn công SQL Injection & XSS ở tầng ứng dụng/biên
const ATTACK_PATTERNS = [
  /(\bor\b|\band\b)\s+['"]?\d+['"]?\s*=\s*['"]?\d+/i,
  /union\s+(all\s+)?select/i,
  /drop\s+table/i,
  /;\s*--/,
  /'\s*--/,
  /<script\b/i,
  /javascript:/i,
  /sleep\s*\(\s*\d+\s*\)/i
];

function hmac(key, data) {
  return crypto.createHmac('sha256', key).update(data, 'utf8').digest();
}

function sha256Hex(data) {
  return crypto.createHash('sha256').update(data, 'utf8').digest('hex');
}

function encodeRfc3986(str) {
  return encodeURIComponent(str).replace(/[!'()*]/g, (c) => '%' + c.charCodeAt(0).toString(16).toUpperCase());
}

/**
 * Tạo đường dẫn S3 Presigned PUT URL chuẩn chữ ký số AWS Signature Version 4
 */
function createS3PresignedPutUrl({ bucket, region, key, expiresSeconds = 300 }) {
  const accessKeyId = process.env.AWS_ACCESS_KEY_ID;
  const secretAccessKey = process.env.AWS_SECRET_ACCESS_KEY;
  const sessionToken = process.env.AWS_SESSION_TOKEN;

  const now = new Date();
  const amzDate = now.toISOString().replace(/[:-]|\.\d{3}/g, '');
  const dateStamp = amzDate.slice(0, 8);
  const host = `${bucket}.s3.${region}.amazonaws.com`;

  const encodedKey = key
    .split('/')
    .map((segment) => encodeRfc3986(segment))
    .join('/');

  const credentialScope = `${dateStamp}/${region}/s3/aws4_request`;
  const queryParams = {
    'X-Amz-Algorithm': 'AWS4-HMAC-SHA256',
    'X-Amz-Credential': `${accessKeyId}/${credentialScope}`,
    'X-Amz-Date': amzDate,
    'X-Amz-Expires': String(expiresSeconds),
    'X-Amz-SignedHeaders': 'host'
  };
  if (sessionToken) {
    queryParams['X-Amz-Security-Token'] = sessionToken;
  }

  const canonicalQueryString = Object.keys(queryParams)
    .sort()
    .map((k) => `${encodeRfc3986(k)}=${encodeRfc3986(queryParams[k])}`)
    .join('&');

  const canonicalRequest = [
    'PUT',
    `/${encodedKey}`,
    canonicalQueryString,
    `host:${host}\n`,
    'host',
    'UNSIGNED-PAYLOAD'
  ].join('\n');

  const stringToSign = [
    'AWS4-HMAC-SHA256',
    amzDate,
    credentialScope,
    sha256Hex(canonicalRequest)
  ].join('\n');

  const kDate = hmac(`AWS4${secretAccessKey}`, dateStamp);
  const kRegion = hmac(kDate, region);
  const kService = hmac(kRegion, 's3');
  const kSigning = hmac(kService, 'aws4_request');
  const signature = crypto.createHmac('sha256', kSigning).update(stringToSign, 'utf8').digest('hex');

  return `https://${host}/${encodedKey}?${canonicalQueryString}&X-Amz-Signature=${signature}`;
}

function formatBytes(bytes) {
  if (!bytes || bytes <= 0) return '0 KB';
  if (bytes >= 1048576) return `${(bytes / 1048576).toFixed(2)} MB`;
  return `${Math.max(0.1, Math.round((bytes / 1024) * 10) / 10)} KB`;
}

async function listPrefixMap(prefix) {
  const res = await s3.send(
    new ListObjectsV2Command({
      Bucket: BUCKET,
      Prefix: prefix,
      MaxKeys: 500
    })
  );
  const map = new Map();
  for (const obj of res.Contents || []) {
    if (obj.Key && obj.Key !== prefix) {
      map.set(obj.Key, obj);
    }
  }
  return map;
}

async function fetchLiveS3Media() {
  const [uploadsMap, processedMap, thumbsMap] = await Promise.all([
    listPrefixMap('uploads/'),
    listPrefixMap('processed/'),
    listPrefixMap('thumbnails/')
  ]);

  const items = [];
  for (const [key, obj] of uploadsMap.entries()) {
    const filename = key.substring('uploads/'.length);
    if (!filename || filename.includes('/')) continue;

    const baseName = filename.replace(/\.[^/.]+$/, '');
    const ext = (filename.split('.').pop() || 'FILE').toUpperCase();
    const origBytes = obj.Size || 0;

    const processedKey = `processed/${baseName}.webp`;
    const procObj = processedMap.get(processedKey);

    const mobileKey = `thumbnails/mobile/${baseName}_320.webp`;
    const tabletKey = `thumbnails/tablet/${baseName}_768.webp`;
    const desktopKey = `thumbnails/desktop/${baseName}_1200.webp`;

    const mobileObj = thumbsMap.get(mobileKey);
    const tabletObj = thumbsMap.get(tabletKey);
    const desktopObj = thumbsMap.get(desktopKey);

    const hasWebp = Boolean(procObj);
    const webpBytes = procObj ? procObj.Size : null;
    const savingsPct =
      hasWebp && origBytes > 0
        ? Math.round(((origBytes - webpBytes) / origBytes) * 1000) / 10
        : null;

    const rawStorage = obj.StorageClass || 'STANDARD';
    const storageClass = rawStorage.includes('GLACIER') ? 'GLACIER_IR' : 'S3_STANDARD';

    const originalCdnUrl = `${CDN_DOMAIN}/uploads/${encodeURIComponent(filename)}`;
    const webpCdnUrl = hasWebp ? `${CDN_DOMAIN}/processed/${encodeURIComponent(baseName)}.webp` : null;

    items.push({
      id: `s3-${filename}`,
      title: filename,
      format: hasWebp ? `WebP (từ ${ext})` : ext,
      originalFormat: ext,
      originalBytes: origBytes,
      originalSizeFormatted: formatBytes(origBytes),
      webpProcessed: hasWebp,
      webpBytes,
      webpSizeFormatted: hasWebp ? formatBytes(webpBytes) : null,
      savingsPct,
      size: hasWebp ? `${formatBytes(webpBytes)} (Gốc: ${formatBytes(origBytes)})` : formatBytes(origBytes),
      storage_class: storageClass,
      lastModified: obj.LastModified ? obj.LastModified.toISOString() : new Date().toISOString(),
      s3_url: `s3://${BUCKET}/${key}`,
      processed_s3_url: hasWebp ? `s3://${BUCKET}/${processedKey}` : null,
      cdn_url: webpCdnUrl || originalCdnUrl,
      original_cdn_url: originalCdnUrl,
      webp_cdn_url: webpCdnUrl,
      thumb: (tabletObj ? `${CDN_DOMAIN}/thumbnails/tablet/${encodeURIComponent(baseName)}_768.webp` : null) || webpCdnUrl || originalCdnUrl,
      thumbnails: {
        mobile: mobileObj ? { url: `${CDN_DOMAIN}/thumbnails/mobile/${encodeURIComponent(baseName)}_320.webp`, size: formatBytes(mobileObj.Size), bytes: mobileObj.Size } : null,
        tablet: tabletObj ? { url: `${CDN_DOMAIN}/thumbnails/tablet/${encodeURIComponent(baseName)}_768.webp`, size: formatBytes(tabletObj.Size), bytes: tabletObj.Size } : null,
        desktop: desktopObj ? { url: `${CDN_DOMAIN}/thumbnails/desktop/${encodeURIComponent(baseName)}_1200.webp`, size: formatBytes(desktopObj.Size), bytes: desktopObj.Size } : null
      },
      isLiveS3: true
    });
  }

  items.sort((a, b) => new Date(b.lastModified).getTime() - new Date(a.lastModified).getTime());
  return items;
}

function jsonResponse(statusCode, payload, extraHeaders = {}) {
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Requested-With',
      ...extraHeaders
    },
    body: JSON.stringify(payload)
  };
}

exports.handler = async (event) => {
  const method = (event.requestContext?.http?.method || event.httpMethod || 'GET').toUpperCase();
  const rawPath = event.rawPath || event.path || '/';
  const query = event.queryStringParameters || {};
  const clientIp = event.requestContext?.http?.sourceIp || '0.0.0.0';

  if (method === 'OPTIONS') {
    return {
      statusCode: 204,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Requested-With',
        'Access-Control-Max-Age': '86400'
      },
      body: ''
    };
  }

  // Kiểm tra Rate Limiting
  const rl = checkRateLimit(clientIp);
  if (!rl.allowed) {
    return jsonResponse(
      429,
      {
        ok: false,
        error: 'Too Many Requests',
        message: 'Vượt quá giới hạn 100 yêu cầu/phút trên mỗi IP. Vui lòng thử lại sau.'
      },
      { 'X-RateLimit-Remaining': '0' }
    );
  }

  let body = {};
  if (event.body) {
    try {
      const rawBody = event.isBase64Encoded
        ? Buffer.from(event.body, 'base64').toString('utf8')
        : event.body;
      body = JSON.parse(rawBody);
    } catch (_) {
      body = {};
    }
  }

  try {
    // 1. Health & Info
    if (rawPath === '/' || rawPath === '/health' || rawPath === '/api/info') {
      return jsonResponse(200, {
        status: 'ok',
        service: 'cloud-media-studio-serverless-api',
        runtime: process.version,
        architecture: process.arch,
        hostname: os.hostname(),
        region: REGION,
        bucket: BUCKET,
        cdnDomain: CDN_DOMAIN
      });
    }

    // 2. WAF / SQLi Protected Search
    if (rawPath === '/api/search' && method === 'GET') {
      const q = String(query.q || '');
      for (const pattern of ATTACK_PATTERNS) {
        if (pattern.test(q)) {
          return jsonResponse(403, {
            ok: false,
            code: 'WAF_SQLI_XSS_BLOCKED',
            message: 'Truy vấn chứa mẫu tấn công độc hại (SQL Injection / XSS) đã bị chặn đứng tại tầng bảo mật!',
            blockedPayload: q
          });
        }
      }
      const items = await fetchLiveS3Media();
      const filtered = items.filter((item) => item.title.toLowerCase().includes(q.toLowerCase()));
      return jsonResponse(200, { ok: true, count: filtered.length, items: filtered });
    }

    // 3. Cấp phát S3 Presigned PUT URL
    if (rawPath === '/api/presign' && method === 'POST') {
      const rawName = String(body.filename || `upload-${Date.now()}.png`).trim();
      const safeFilename = rawName
        .replace(/\s+/g, '-')
        .replace(/[^a-zA-Z0-9._-]/g, '');

      const finalFilename = safeFilename || `asset-${Date.now()}.png`;
      const s3Key = `uploads/${finalFilename}`;
      const baseName = finalFilename.replace(/\.[^/.]+$/, '');

      const uploadUrl = createS3PresignedPutUrl({
        bucket: BUCKET,
        region: REGION,
        key: s3Key,
        expiresSeconds: 300
      });

      return jsonResponse(200, {
        ok: true,
        uploadUrl,
        expiresInSeconds: 300,
        filename: finalFilename,
        baseName,
        s3Key,
        s3Uri: `s3://${BUCKET}/${s3Key}`,
        cloudFrontUrl: `${CDN_DOMAIN}/uploads/${encodeURIComponent(finalFilename)}`,
        expectedWebpUrl: `${CDN_DOMAIN}/processed/${encodeURIComponent(baseName)}.webp`,
        expectedThumbnails: {
          mobile: `${CDN_DOMAIN}/thumbnails/mobile/${encodeURIComponent(baseName)}_320.webp`,
          tablet: `${CDN_DOMAIN}/thumbnails/tablet/${encodeURIComponent(baseName)}_768.webp`,
          desktop: `${CDN_DOMAIN}/thumbnails/desktop/${encodeURIComponent(baseName)}_1200.webp`
        }
      });
    }

    // 4. Đọc danh sách tài nguyên thật trực tiếp từ Amazon S3
    if (rawPath === '/api/s3-media' && method === 'GET') {
      const items = await fetchLiveS3Media();
      return jsonResponse(200, {
        ok: true,
        bucket: BUCKET,
        cdnDomain: CDN_DOMAIN,
        count: items.length,
        items
      });
    }

    // 5. Chuyển đối tượng thật trên S3 sang kho lạnh S3 Glacier Instant Retrieval (GLACIER_IR)
    if (rawPath === '/api/s3-archive' && method === 'POST') {
      const filename = String(body.filename || '').trim();
      if (!filename || filename.includes('/')) {
        return jsonResponse(400, { ok: false, error: 'Tên file không hợp lệ' });
      }
      const srcKey = `uploads/${filename}`;
      await s3.send(
        new CopyObjectCommand({
          Bucket: BUCKET,
          CopySource: `${BUCKET}/${encodeRfc3986('uploads')}/${encodeRfc3986(filename)}`,
          Key: srcKey,
          StorageClass: 'GLACIER_IR',
          MetadataDirective: 'COPY'
        })
      );

      return jsonResponse(200, {
        ok: true,
        filename,
        s3Uri: `s3://${BUCKET}/${srcKey}`,
        storageClass: 'GLACIER_IR',
        message: `Đã chuyển đối tượng "${filename}" sang lớp lưu trữ lạnh S3 Glacier Instant Retrieval thực tế trên AWS!`
      });
    }

    // 6. Xóa đối tượng thật cùng các bản nén WebP & Thumbnails trên S3
    if ((rawPath === '/api/s3-delete' && method === 'POST') || (rawPath === '/api/s3-delete' && method === 'DELETE')) {
      const filename = String(body.filename || '').trim();
      if (!filename || filename.includes('/')) {
        return jsonResponse(400, { ok: false, error: 'Tên file không hợp lệ' });
      }
      const baseName = filename.replace(/\.[^/.]+$/, '');
      const objectsToDelete = [
        { Key: `uploads/${filename}` },
        { Key: `processed/${baseName}.webp` },
        { Key: `thumbnails/mobile/${baseName}_320.webp` },
        { Key: `thumbnails/tablet/${baseName}_768.webp` },
        { Key: `thumbnails/desktop/${baseName}_1200.webp` }
      ];

      await s3.send(
        new DeleteObjectsCommand({
          Bucket: BUCKET,
          Delete: { Objects: objectsToDelete, Quiet: true }
        })
      );

      return jsonResponse(200, {
        ok: true,
        filename,
        deletedKeys: objectsToDelete.map((o) => o.Key),
        message: `Đã xóa sạch "${filename}" cùng toàn bộ bản WebP và Thumbnails trên S3.`
      });
    }

    return jsonResponse(404, { ok: false, error: 'Endpoint Not Found', path: rawPath });
  } catch (err) {
    console.error('[CloudMediaAPI Error]:', err);
    return jsonResponse(500, { ok: false, error: err.message });
  }
};

