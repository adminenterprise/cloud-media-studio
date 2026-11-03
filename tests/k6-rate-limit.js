/**
 * ==============================================================================
 * CLOUD MEDIA STUDIO — K6 RATE LIMITING & DDOS LOAD TEST SCRIPT
 * ==============================================================================
 * Chạy bằng k6:
 *    k6 run tests/k6-rate-limit.js
 * Hoặc truyền URL mục tiêu:
 *    k6 run -e TARGET_URL=http://localhost:3000/api/search tests/k6-rate-limit.js
 * Hoặc test trực tiếp trên AWS WAF (ALB):
 *    k6 run -e TARGET_URL=http://<ALB-DNS-NAME>/api/search tests/k6-rate-limit.js
 * ==============================================================================
 */

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Đo tỉ lệ request bị Rate Limit (HTTP 429 hoặc HTTP 403 do AWS WAF)
export const errorRate = new Rate('rate_limited_requests');

export const options = {
  // Giai đoạn tạo tải dồn dập (Burst Traffic)
  stages: [
    { duration: '3s', target: 20 },  // Bắt đầu 20 người dùng đồng thời (VUs)
    { duration: '5s', target: 50 },  // Đẩy lên 50 VUs (vượt ngưỡng Rate Limit)
    { duration: '2s', target: 0 },   // Hạ nhiệt
  ],
  thresholds: {
    // Kì vọng phát hiện được cơ chế Rate Limiting kích hoạt
    http_req_duration: ['p(95)<1000'], // 95% request dưới 1s
  },
};

export default function () {
  const url = __ENV.TARGET_URL || 'http://localhost:3000/api/info';
  
  const res = http.get(url);

  // Kiểm tra phản hồi: 200 OK (thông thường) hoặc 429/403 (khi bị Rate Limit)
  const isOk = res.status === 200;
  const isRateLimited = res.status === 429 || res.status === 403;

  check(res, {
    'Status là 200 OK (Allowed)': (r) => r.status === 200,
    'Status là 429 Too Many Requests hoặc 403 WAF Blocked': (r) => isRateLimited,
  });

  errorRate.add(isRateLimited);

  sleep(0.05); // gửi request cách nhau 50ms để tạo tải dồn dập
}
