# 🎬 TỔNG QUAN DỰ ÁN: CLOUD MEDIA STUDIO
### Hệ Thống Biên Tập, Chuyển Đổi & Phân Phối Truyền Thông Đa Phương Tiện Doanh Nghiệp Trên AWS Tích Hợp DevSecOps

---

### 1. Ý tưởng cốt lõi và Sản phẩm (Core Product)

- **Mô hình kiến trúc:** Xây dựng nền tảng **SaaS Media Hub** doanh nghiệp (tương tự Cloudinary hoặc Canva thu nhỏ), kết hợp giữa kiến trúc ứng dụng web đa tầng (`3-Tier Architecture Multi-AZ`) và đường ống xử lý không máy chủ (`Serverless Pipeline`) phục vụ Content Creator và Marketing.
- **Tính năng sản phẩm cốt lõi:**
  1. **Tải lên tài nguyên (Upload):** Người dùng tải ảnh chất lượng cao (4K UHD) hoặc video ngắn lên hệ thống.
  2. **Xử lý tự động (AI/Serverless Pipeline):** Sự kiện `s3:ObjectCreated` kích hoạt AWS Lambda tự động nén sang WebP, sinh 3 kích thước Thumbnail (Mobile 320w, Tablet 768w, Desktop 1200w).
  3. **Quản lý & Tìm kiếm kho Media:** Tra cứu, lọc theo tags phân loại, dung lượng, định dạng, tác giả.
  4. **Lưu trữ vòng đời thông minh (FinOps Lifecycle Archiving):** Ảnh/video sau 30 ngày tự động chuyển vào kho lưu trữ lạnh `S3 Glacier` giúp giảm hơn 84% chi phí lưu trữ.

---

### 2. Thiết kế Kiến trúc Hệ thống (System Architecture)

```
[ NGƯỜI DÙNG / CREATOR ]
          │
          ▼
[ Amazon Route 53 (DNS) + Amazon CloudFront (CDN) + AWS WAF (Tường lửa Web) ]
          │
          ▼
┌────────────────────── PRODUCTION VPC (10.0.0.0/16) - Multi-AZ ──────────────────────┐
│                                                                                     │
│  [ Public Subnets - Tầng Biên (Edge Tier) ]                                         │
│  ├── Internet Gateway (Cổng kết nối Internet)                                       │
│  ├── Application Load Balancer - ALB (Cân bằng tải ứng dụng đa vùng AZ)             │
│  └── NAT Gateway (Cổng dịch địa chỉ mạng cho phép máy chủ nội bộ tải bản vá)         │
│                                                                                     │
│  [ Private Subnets - Tầng Tính toán (Compute Tier) ]                                │
│  ├── Amazon ECS + AWS Fargate (API Service xử lý nghiệp vụ Media Studio)            │
│  ├── AWS Lambda (Hàm Serverless tự động bắt sự kiện S3 nén ảnh WebP & Thumbnails)   │
│  └── Amazon EFS (Hệ thống tệp mạng chia sẻ giữa các container/máy chủ)              │
│                                                                                     │
│  [ Private Subnets - Tầng Dữ liệu (Database Tier - Cách ly hoàn toàn) ]              │
│  ├── Amazon RDS MySQL Multi-AZ (Lưu Metadata: tên file, kích thước, tags, author)   │
│  └── Amazon DynamoDB (NoSQL lưu trữ lượt tải, lượt xem và hàng đợi xử lý media)     │
│                                                                                     │
│  [ Tầng Lưu trữ Đối tượng S3 & FinOps Lifecycle ]                                   │
│  ├── S3 Raw Bucket: Chứa ảnh/video gốc người dùng tải lên                           │
│  ├── S3 Processed Bucket: Chứa ảnh đã nén WebP, 3 bản Thumbnail                     │
│  └── S3 Glacier: Tự động chuyển media cũ sau 30 ngày (Tiết kiệm 84% chi phí)        │
│                                                                                     │
└──────────────────────────────────────────┬──────────────────────────────────────────┘
                                           │
                         [ AWS VPC Peering / Transit Gateway ]
                                           │ (Định tuyến nội bộ mã hóa qua AWS Backbone)
                                           ▼
┌────────────────── MANAGEMENT & DEVSECOPS VPC (10.1.0.0/16) ─────────────────────────┐
│                                                                                     │
│  • AWS Secrets Manager: Quản lý tập trung mật khẩu DB, không hardcode trong mã code │
│  • AWS KMS: Dịch vụ quản lý khóa mã hóa dữ liệu tại chỗ (Encryption at Rest)        │
│  • Bastion Host: Quản trị nội bộ bảo mật qua AWS SSM Session Manager                │
│  • GitHub Actions Runner + Trivy: Tự động kiểm thử mã nguồn và quét lỗ hổng bảo mật │
│                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

### 3. "Điểm Sáng Ăn Điểm" — 5 Chốt Chặn DevSecOps CI/CD

Đường ống CI/CD GitHub Actions (`.github/workflows/ci.yml`):

1. **Chốt 1: Syntax & Health Check Liveness:**
   - Kiểm tra cú pháp: `node --check server.js`
   - Chạy thử backend độc lập, tự động gọi `/health`, `/api/info`, `/api/media` đảm bảo code không crash.
2. **Chốt 2: Aqua Security Trivy Container Scanner:**
   - Tự động quét Docker Image của Backend và Frontend trước khi đóng gói.
   - Ngưỡng: Nếu dính lỗ hổng **CRITICAL/HIGH** chưa vá, đường ống sẽ cảnh báo và chặn lại.
3. **Chốt 3: Zero Secret Keys via AWS OIDC:**
   - Tuyệt đối không lưu static `AWS_ACCESS_KEY_ID` hay `AWS_SECRET_ACCESS_KEY` trong GitHub Secrets.
   - GitHub Actions kết nối với AWS IAM thông qua OpenID Connect (OIDC) xin cấp mã JWT ngắn hạn, AWS cấp quyền `AssumeRole` tạm thời.
4. **Chốt 4: Gắn thẻ Bất biến (Immutable Tagging Strategy):**
   - Mỗi ảnh Docker đẩy lên ECR được gắn thẻ theo mã băm commit: `backend:sha-5e038b6`.
   - Chống bị ghi đè nhầm phiên bản, truy vết 100% dòng code trên web đang chạy từ commit nào.
5. **Chốt 5: Tự động hóa Hạ tầng (Terraform CI):**
   - File `.github/workflows/terraform.yml` tự động chạy `fmt`, `validate` và `plan -lock=false` mỗi khi có thay đổi hạ tầng.

---

### 4. Bảng Phân Công 4 Thành Viên Cho Buổi Báo Cáo Hội Đồng

| Thành viên | Phân mảng | Trách nhiệm cụ thể trong Cloud Media Studio | Kịch bản Demo thực chứng trước Hội đồng |
| :--- | :--- | :--- | :--- |
| **Member 1 (Nhóm trưởng)** | **Mạng & IaC** | • Thiết kế Dual-VPC Peering, chia 6 Subnets Multi-AZ.<br>• Cấu hình ALB và WAFv2 bảo vệ cổng Media. | **Trình diễn Mạng & High Availability:** Mở giao diện Web, nhấn Refresh để thấy Hostname thay đổi giữa các container ECS Fargate Multi-AZ (Load Balancing & Self-Healing). |
| **Member 2** | **Tính toán & Container** | • Viết code Web Media Studio (Upload file, danh sách ảnh/video).<br>• Đóng gói Docker, cấu hình ECS Fargate.<br>• Viết hàm AWS Lambda tự động nén ảnh khi có sự kiện S3. | **Trình diễn Serverless Lambda:** Tải ảnh lên web, chỉ cho Thầy thấy Lambda lập tức sinh 3 kích thước Thumbnail (Mobile, Tablet, Desktop) và chuyển sang WebP giảm 84% dung lượng. |
| **Member 3** | **Dữ liệu & FinOps** | • Tạo RDS MySQL lưu bảng Metadata (tên file, kích thước, tag).<br>• Cấu hình S3 Lifecycle đẩy media cũ sau 30 ngày sang S3 Glacier.<br>• Cài đặt AWS Budgets ($200) và Dashboard CloudWatch theo dõi chi phí. | **Trình diễn FinOps S3 Glacier:** Mở AWS Budgets và Dashboard chứng minh chi phí lưu trữ được tối ưu nhờ S3 Glacier ($0.004/GB vs $0.025/GB, tiết kiệm $9.82 / $200). |
| **Member 4** | **Bảo mật & DevSecOps** | • Xây dựng đường ống CI/CD GitHub Actions tích hợp Trivy Scanner và xác thực OIDC.<br>• Cấu hình AWS WAF chặn đứng SQLi vào ô tìm kiếm ảnh và Rate Limit chống spam upload.<br>• Cấu hình AWS Secrets Manager lưu mật khẩu DB. | **Trình diễn WAF Defense:** Gửi lệnh `curl` chứa chuỗi SQLi `' OR 1=1 --` vào thanh tìm kiếm ảnh, chỉ cho Thầy thấy AWS WAF chặn đứng ngay lập tức với mã **HTTP 403 Forbidden**. |
