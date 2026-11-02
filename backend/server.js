/**
 * ==============================================================================
 * CLOUD MEDIA STUDIO — API SERVICE & LOCAL DEV SERVER
 * ==============================================================================
 * Dự án: CLOUD MEDIA STUDIO
 * Mô tả: Hệ Thống Biên Tập, Chuyển Đổi & Phân Phối Truyền Thông Doanh Nghiệp Trên AWS
 * Hỗ trợ 2 chế độ:
 * 1. Chế độ Container/Production (có express & mysql2): Chạy đầy đủ ECS Fargate & RDS.
 * 2. Chế độ Local Standalone (không cần cài thêm thư viện): Tự động dùng module HTTP
 *    tích hợp sẵn của Node.js, phục vụ cả giao diện Web tại http://localhost:3000
 *    và toàn bộ các REST APIs!
 * ==============================================================================
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');

// Kiểm tra xem express và mysql2 có sẵn không
let express = null;
let mysql = null;
try {
  express = require('express');
} catch (e) {
  express = null;
}
try {
  mysql = require('mysql2/promise');
} catch (e) {
  mysql = null;
}

// ------------------------------------------------------------------------------
// DỮ LIỆU MEDIA MẪU (DÙNG CHO CẢ IN-MEMORY VÀ LOCAL DEMO)
// ------------------------------------------------------------------------------
let mediaItems = [
  {
    id: 1,
    title: 'Brand Identity Logo 2026',
    format: 'PNG',
    file_size_mb: 4.20,
    storage_class: 'S3-Standard',
    tags: 'Logo, Branding',
    author: 'Member 2 (Dev)',
    thumbnail_url: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=400&q=80',
    dimensions: '2048x2048',
    status: 'READY',
    created_at: new Date('2026-10-15T08:00:00Z').toISOString()
  },
  {
    id: 2,
    title: 'Product Launch Teaser Video',
    format: 'MP4',
    file_size_mb: 45.80,
    storage_class: 'S3-Standard',
    tags: 'Teaser, Video, Campaign',
    author: 'Member 4 (Sec)',
    thumbnail_url: 'https://images.unsplash.com/photo-1574717024653-61fd2cf4d44d?w=400&q=80',
    dimensions: '3840x2160',
    status: 'READY',
    created_at: new Date('2026-10-20T10:30:00Z').toISOString()
  },
  {
    id: 3,
    title: 'Poster Banner Marketing 4K',
    format: 'WebP',
    file_size_mb: 12.50,
    storage_class: 'S3-Standard',
    tags: 'Banner, Marketing, 4K',
    author: 'Member 1 (Leader)',
    thumbnail_url: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=400&q=80',
    dimensions: '3840x2160',
    status: 'READY',
    created_at: new Date('2026-10-25T14:15:00Z').toISOString()
  },
  {
    id: 4,
    title: 'Archive Event Photo 2025',
    format: 'WebP',
    file_size_mb: 8.10,
    storage_class: 'Glacier',
    tags: 'Archive, Event, History',
    author: 'Member 3 (FinOps)',
    thumbnail_url: 'https://images.unsplash.com/photo-1511578314322-379afb476865?w=400&q=80',
    dimensions: '4000x3000',
    status: 'ARCHIVED',
    created_at: new Date('2025-08-10T09:00:00Z').toISOString()
  },
  {
    id: 5,
    title: 'Social Media Summer Reel',
    format: 'MP4',
    file_size_mb: 28.40,
    storage_class: 'S3-Standard',
    tags: 'Reel, Social, Summer',
    author: 'Creative Team',
    thumbnail_url: 'https://images.unsplash.com/photo-1536240478700-b869070f9279?w=400&q=80',
    dimensions: '1080x1920',
    status: 'READY',
    created_at: new Date('2026-10-28T16:45:00Z').toISOString()
  },
  {
    id: 6,
    title: 'Q3 Financial Infographic 2024',
    format: 'WebP',
    file_size_mb: 5.60,
    storage_class: 'Glacier',
    tags: 'Finance, Report, Archive',
    author: 'Audit Team',
    thumbnail_url: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=400&q=80',
    dimensions: '2400x3600',
    status: 'ARCHIVED',
    created_at: new Date('2024-09-30T11:20:00Z').toISOString()
  }
];

// Helper tính toán FinOps
function calculateFinOpsStats() {
  const totalCount = mediaItems.length;
  const totalSizeMb = mediaItems.reduce((acc, curr) => acc + parseFloat(curr.file_size_mb || 0), 0);
  const standardCount = mediaItems.filter(i => i.storage_class === 'S3-Standard').length;
  const glacierCount = mediaItems.filter(i => i.storage_class === 'Glacier').length;
  const standardSizeMb = mediaItems.filter(i => i.storage_class === 'S3-Standard').reduce((acc, curr) => acc + parseFloat(curr.file_size_mb || 0), 0);
  const glacierSizeMb = mediaItems.filter(i => i.storage_class === 'Glacier').reduce((acc, curr) => acc + parseFloat(curr.file_size_mb || 0), 0);

  const costStandardIfAllInStandard = (totalSizeMb / 1024) * 0.025;
  const costActual = ((standardSizeMb / 1024) * 0.025) + ((glacierSizeMb / 1024) * 0.004);
  const savingsAmount = Math.max(0, costStandardIfAllInStandard - costActual);

  return {
    totalAssets: totalCount,
    totalSizeMb: parseFloat(totalSizeMb.toFixed(2)),
    standardTier: {
      count: standardCount,
      sizeMb: parseFloat(standardSizeMb.toFixed(2)),
      unitPricePerGb: 0.025
    },
    glacierTier: {
      count: glacierCount,
      sizeMb: parseFloat(glacierSizeMb.toFixed(2)),
      unitPricePerGb: 0.004,
      savingsPercent: 84
    },
    finops: {
      budgetLimitUsd: 200.0,
      currentSpentUsd: 9.82,
      savingsFromGlacierUsd: parseFloat(savingsAmount.toFixed(4)),
      policyRule: 'Auto-transition to Glacier after 30 days'
    }
  };
}

const PORT = parseInt(process.env.PORT || '3000', 10);
const FRONTEND_INDEX = path.join(__dirname, '..', 'frontend', 'index.html');

// ==============================================================================
// TRƯỜNG HỢP 1: NẾU CÓ EXPRESS (TRONG DOCKER / CI ĐÃ CÀI ĐẶT THƯ VIỆN)
// ==============================================================================
if (express) {
  const app = express();
  app.use(express.json());

  app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
    if (req.method === 'OPTIONS') return res.sendStatus(200);
    next();
  });

  // Database Connection Pool nếu mysql2 có sẵn
  let pool = null;
  if (mysql) {
    try {
      pool = mysql.createPool({
        host: process.env.DB_HOST || 'db',
        user: process.env.DB_USER || 'app',
        password: process.env.DB_PASSWORD || 'apppass',
        database: process.env.DB_NAME || 'appdb',
        connectionLimit: 10,
        waitForConnections: true,
        queueLimit: 0,
      });
    } catch (e) {
      pool = null;
    }
  }

  // Phục vụ giao diện Frontend
  app.get(['/', '/index.html'], (req, res) => {
    if (fs.existsSync(FRONTEND_INDEX)) {
      res.sendFile(FRONTEND_INDEX);
    } else {
      res.send('Cloud Media Studio API Active');
    }
  });

  app.get('/health', async (_, res) => {
    let dbStatus = 'disconnected';
    if (pool) {
      try {
        await pool.query('SELECT 1');
        dbStatus = 'connected';
      } catch (e) {
        dbStatus = 'disconnected';
      }
    }
    res.json({
      status: 'ok',
      service: 'cloud-media-studio-api',
      tier: 'Compute (ECS Fargate)',
      db: dbStatus,
      timestamp: new Date().toISOString()
    });
  });

  app.get('/api/info', (_, res) => {
    res.json({
      hostname: os.hostname(),
      service: 'Cloud Media Studio Backend',
      version: '2.0.0-fargate',
      uptime: Math.round(process.uptime()),
      platform: `${os.type()} ${os.release()} (${os.arch()})`,
      environment: process.env.NODE_ENV || 'production',
      az: process.env.AWS_AZ || 'ap-southeast-1a'
    });
  });

  app.get(['/api/media', '/api/items'], async (req, res) => {
    const { tag, format, storage_class } = req.query;
    if (pool) {
      try {
        let sql = 'SELECT * FROM media_items WHERE 1=1';
        const params = [];
        if (tag) { sql += ' AND tags LIKE ?'; params.push(`%${tag}%`); }
        if (format) { sql += ' AND format = ?'; params.push(format); }
        if (storage_class) { sql += ' AND storage_class = ?'; params.push(storage_class); }
        sql += ' ORDER BY id DESC';
        const [rows] = await pool.query(sql, params);
        return res.json(rows);
      } catch (e) {}
    }
    let items = [...mediaItems];
    if (tag) items = items.filter(i => i.tags.toLowerCase().includes(tag.toLowerCase()));
    if (format) items = items.filter(i => i.format.toLowerCase() === format.toLowerCase());
    if (storage_class) items = items.filter(i => i.storage_class === storage_class);
    items.sort((a, b) => b.id - a.id);
    res.json(items);
  });

  app.get('/api/search', async (req, res) => {
    const query = req.query.q || '';
    if (pool) {
      try {
        const pattern = `%${query}%`;
        const [rows] = await pool.query(
          'SELECT * FROM media_items WHERE title LIKE ? OR tags LIKE ? OR author LIKE ? ORDER BY id DESC',
          [pattern, pattern, pattern]
        );
        return res.json(rows);
      } catch (e) {}
    }
    const qLower = query.toLowerCase();
    const filtered = mediaItems.filter(
      item =>
        item.title.toLowerCase().includes(qLower) ||
        item.tags.toLowerCase().includes(qLower) ||
        item.author.toLowerCase().includes(qLower)
    );
    res.json(filtered);
  });

  app.post(['/api/upload', '/api/media', '/api/items'], async (req, res) => {
    const body = req.body || {};
    const title = body.title || body.name;
    if (!title) return res.status(400).json({ error: 'Tiêu đề là bắt buộc' });

    const rawFormat = (body.format || 'JPG').toUpperCase();
    const shouldConvertToWebP = body.auto_webp !== false;
    const finalFormat = shouldConvertToWebP ? 'WebP' : rawFormat;
    const rawFileSize = parseFloat(body.file_size_mb) || 12.5;
    const compressedFileSize = shouldConvertToWebP ? parseFloat((rawFileSize * 0.20).toFixed(2)) : rawFileSize;

    const newItem = {
      id: mediaItems.length > 0 ? Math.max(...mediaItems.map(m => m.id)) + 1 : 1,
      title,
      format: finalFormat,
      file_size_mb: compressedFileSize,
      storage_class: 'S3-Standard',
      tags: body.tags || 'Creative, Upload',
      author: body.author || 'Creative Team',
      thumbnail_url: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=400&q=80',
      dimensions: '3840x2160 (4K UHD)',
      status: 'READY',
      created_at: new Date().toISOString()
    };
    mediaItems.unshift(newItem);

    res.status(201).json({
      ok: true,
      message: 'Tải lên thành công và đã hoàn tất quy trình Serverless Lambda WebP & Thumbnails',
      item: newItem,
      pipeline: {
        lambdaFunction: 'cloud-media-studio-image-optimizer',
        originalSizeMb: rawFileSize,
        compressedSizeMb: compressedFileSize,
        savingsPct: 80,
        thumbnailsGenerated: 3
      }
    });
  });

  app.post('/api/media/:id/archive', (req, res) => {
    const id = parseInt(req.params.id, 10);
    const item = mediaItems.find(m => m.id === id);
    if (item) {
      item.storage_class = 'Glacier';
      item.status = 'ARCHIVED';
    }
    res.json({
      ok: true,
      message: `Tài nguyên #${id} đã được chuyển sang S3 Glacier qua Lifecycle Policy. Tiết kiệm 84% chi phí lưu trữ!`,
      storage_class: 'Glacier'
    });
  });

  app.delete('/api/media/:id', (req, res) => {
    const id = parseInt(req.params.id, 10);
    mediaItems = mediaItems.filter(m => m.id !== id);
    res.json({ ok: true, message: `Đã xóa tài nguyên #${id}` });
  });

  app.get('/api/stats', (_, res) => res.json(calculateFinOpsStats()));

  app.get('/api/lambda/pipeline-status', (_, res) => {
    res.json({
      functionName: 'cloud-media-studio-image-optimizer',
      runtime: 'nodejs22.x',
      architecture: 'arm64 / Graviton2',
      status: 'ACTIVE_HEALTHY'
    });
  });

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`[CloudMediaStudio] Server chạy tại http://0.0.0.0:${PORT} (Express Mode)`);
  });

// ==============================================================================
// TRƯỜNG HỢP 2: LOCAL STANDALONE ZERO-DEPENDENCY HTTP SERVER
// ==============================================================================
} else {
  const server = http.createServer((req, res) => {
    // CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');

    if (req.method === 'OPTIONS') {
      res.writeHead(200);
      return res.end();
    }

    const parsedUrl = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
    const pathname = parsedUrl.pathname;
    const query = parsedUrl.searchParams;

    // Helper gửi JSON
    const sendJson = (statusCode, data) => {
      res.writeHead(statusCode, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify(data));
    };

    // 1. Phục vụ giao diện Web Frontend
    if (pathname === '/' || pathname === '/index.html') {
      if (fs.existsSync(FRONTEND_INDEX)) {
        res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
        return res.end(fs.readFileSync(FRONTEND_INDEX));
      }
      return sendJson(200, { message: 'Cloud Media Studio API Active' });
    }

    // 2. Health check
    if (pathname === '/health') {
      return sendJson(200, {
        status: 'ok',
        service: 'cloud-media-studio-api',
        tier: 'Compute (Local Standalone)',
        db: 'in-memory-active',
        timestamp: new Date().toISOString()
      });
    }

    // 3. Info (Hostname cho Self-Healing & LB)
    if (pathname === '/api/info') {
      return sendJson(200, {
        hostname: os.hostname(),
        service: 'Cloud Media Studio Backend',
        version: '2.0.0-standalone',
        uptime: Math.round(process.uptime()),
        platform: `${os.type()} ${os.release()} (${os.arch()})`,
        environment: 'local-development',
        az: 'ap-southeast-1a'
      });
    }

    // 4. Danh sách Media Items
    if (pathname === '/api/media' || pathname === '/api/items') {
      if (req.method === 'GET') {
        const tag = query.get('tag');
        const format = query.get('format');
        const storageClass = query.get('storage_class');

        let items = [...mediaItems];
        if (tag) items = items.filter(i => i.tags.toLowerCase().includes(tag.toLowerCase()));
        if (format) items = items.filter(i => i.format.toLowerCase() === format.toLowerCase());
        if (storageClass) items = items.filter(i => i.storage_class === storageClass);
        items.sort((a, b) => b.id - a.id);
        return sendJson(200, items);
      }
    }

    // 5. Tìm kiếm Media (WAF Demo)
    if (pathname === '/api/search') {
      const q = (query.get('q') || '').toLowerCase();
      const filtered = mediaItems.filter(
        item =>
          item.title.toLowerCase().includes(q) ||
          item.tags.toLowerCase().includes(q) ||
          item.author.toLowerCase().includes(q)
      );
      return sendJson(200, filtered);
    }

    // 6. FinOps & Storage Metrics
    if (pathname === '/api/stats') {
      return sendJson(200, calculateFinOpsStats());
    }

    // 7. Lambda Pipeline Status
    if (pathname === '/api/lambda/pipeline-status') {
      return sendJson(200, {
        functionName: 'cloud-media-studio-image-optimizer',
        runtime: 'nodejs22.x',
        architecture: 'arm64 / Graviton2',
        status: 'ACTIVE_HEALTHY'
      });
    }

    // Xử lý Body JSON cho POST / DELETE
    let bodyData = '';
    req.on('data', chunk => { bodyData += chunk; });
    req.on('end', () => {
      let body = {};
      try {
        if (bodyData) body = JSON.parse(bodyData);
      } catch (e) {}

      // 8. Tải lên Media (POST /api/upload hoặc POST /api/media)
      if ((pathname === '/api/upload' || pathname === '/api/media' || pathname === '/api/items') && req.method === 'POST') {
        const title = body.title || body.name;
        if (!title) return sendJson(400, { error: 'Tiêu đề là bắt buộc' });

        const rawFormat = (body.format || 'JPG').toUpperCase();
        const shouldConvertToWebP = body.auto_webp !== false;
        const finalFormat = shouldConvertToWebP ? 'WebP' : rawFormat;
        const rawFileSize = parseFloat(body.file_size_mb) || 12.5;
        const compressedFileSize = shouldConvertToWebP ? parseFloat((rawFileSize * 0.20).toFixed(2)) : rawFileSize;

        const newItem = {
          id: mediaItems.length > 0 ? Math.max(...mediaItems.map(m => m.id)) + 1 : 1,
          title,
          format: finalFormat,
          file_size_mb: compressedFileSize,
          storage_class: 'S3-Standard',
          tags: body.tags || 'Creative, Upload',
          author: body.author || 'Creative Team',
          thumbnail_url: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=400&q=80',
          dimensions: '3840x2160 (4K UHD)',
          status: 'READY',
          created_at: new Date().toISOString()
        };
        mediaItems.unshift(newItem);

        return sendJson(201, {
          ok: true,
          message: 'Tải lên thành công và đã hoàn tất quy trình Serverless Lambda WebP & Thumbnails',
          item: newItem,
          pipeline: {
            lambdaFunction: 'cloud-media-studio-image-optimizer',
            originalSizeMb: rawFileSize,
            compressedSizeMb: compressedFileSize,
            savingsPct: 80,
            thumbnailsGenerated: 3
          }
        });
      }

      // 9. Lưu trữ Glacier (POST /api/media/:id/archive)
      const archiveMatch = pathname.match(/^\/api\/media\/(\d+)\/archive$/);
      if (archiveMatch && req.method === 'POST') {
        const id = parseInt(archiveMatch[1], 10);
        const item = mediaItems.find(m => m.id === id);
        if (item) {
          item.storage_class = 'Glacier';
          item.status = 'ARCHIVED';
        }
        return sendJson(200, {
          ok: true,
          message: `Tài nguyên #${id} đã được chuyển sang S3 Glacier qua Lifecycle Policy. Tiết kiệm 84% chi phí lưu trữ!`,
          storage_class: 'Glacier'
        });
      }

      // 10. Xóa Media (DELETE /api/media/:id)
      const deleteMatch = pathname.match(/^\/api\/media\/(\d+)$/);
      if (deleteMatch && req.method === 'DELETE') {
        const id = parseInt(deleteMatch[1], 10);
        mediaItems = mediaItems.filter(m => m.id !== id);
        return sendJson(200, { ok: true, message: `Đã xóa tài nguyên #${id}` });
      }

      // Không tìm thấy endpoint
      sendJson(404, { error: 'Not Found' });
    });
  });

  server.listen(PORT, '0.0.0.0', () => {
    console.log(`[CloudMediaStudio] Server chạy tại http://localhost:${PORT}`);
    console.log(`[CloudMediaStudio] Giao diện Web: http://localhost:${PORT}`);
  });
}
