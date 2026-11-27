# Cloud Media Studio

**Nền tảng Quản trị, Chuyển đổi WebP Tự động & Phân phối Đa phương tiện trên AWS Public Cloud**

[![Deploy Frontend](https://github.com/adminenterprise/cloud-media-studio/actions/workflows/deploy-frontend.yml/badge.svg)](https://github.com/adminenterprise/cloud-media-studio/actions/workflows/deploy-frontend.yml)
[![DevSecOps CI](https://github.com/adminenterprise/cloud-media-studio/actions/workflows/ci.yml/badge.svg)](https://github.com/adminenterprise/cloud-media-studio/actions/workflows/ci.yml)
[![Terraform IaC](https://github.com/adminenterprise/cloud-media-studio/actions/workflows/terraform.yml/badge.svg)](https://github.com/adminenterprise/cloud-media-studio/actions/workflows/terraform.yml)
[![AWS Region](https://img.shields.io/badge/AWS-ap--southeast--1%20(Singapore)-FF9900?logo=amazonwebservices&logoColor=white)](https://aws.amazon.com/)
[![Live Demo](https://img.shields.io/badge/Live%20Demo-cloudmedia.duccloud.men-10B981)](https://cloudmedia.duccloud.men/)

> **Học phần:** Điện toán Đám mây (`2627I_INT3319E_2`) — Trường Đại học Công nghệ, ĐHQGHN  
> **Giảng viên hướng dẫn:** Nguyễn Ngọc Tân  
> **Nhóm thực hiện:** Nhóm 1 — NovaCloud Consulting  
> **Ứng dụng trực tuyến (HTTPS + CloudFront CDN):** [https://cloudmedia.duccloud.men/](https://cloudmedia.duccloud.men/)

---

## 1. Tổng quan bài toán & Điểm nổi bật

**Cloud Media Studio** giải quyết bài toán quản trị, tối ưu dung lượng và phân phối kho ảnh/video truyền thông cho doanh nghiệp thay thế máy chủ vật lý (NAS) hay quá tải và tốn chi phí cố định:

- **Tải tệp an toàn không lộ khóa AWS:** Trình duyệt gọi Lambda API xin **S3 Presigned PUT URL** (ký `AWS4-HMAC-SHA256`, hạn 300 giây) và tải thẳng lên S3, vượt giới hạn payload 6 MB của Lambda.
- **Nén WebP & cắt Thumbnail tự động (Serverless ARM64):** Sự kiện `s3:ObjectCreated` (khóa `filter_prefix = "uploads/"` chống lặp vô hạn) kích hoạt **AWS Lambda Node.js 22 trên chip ARM64 Graviton2** chạy `sharp/libvips`, xuất song song **1 bản `.webp` chính** (giảm tới **97,6%** dung lượng với ảnh mẫu 3,04 MB → 74,4 KB) và **3 ảnh thu nhỏ** (`320w`, `768w`, `1200w`).
- **Khóa kín S3 & Phân phối biên tốc độ cao:** Bật `Block All Public Access = ON` trên S3; toàn bộ chiều đọc đi qua **Amazon CloudFront CDN** + **Origin Access Control (OAC)** với chứng chỉ TLS từ **AWS ACM** cho tên miền riêng `cloudmedia.duccloud.men` (độ trễ < 45 ms tại Việt Nam).
- **Tối ưu chi phí (FinOps):** Giảm **~84%** chi phí lưu trữ ảnh cũ nhờ **S3 Glacier Instant Retrieval** (chuyển tức thì từ giao diện web) & **S3 Lifecycle Rule** (tự động sau 30 ngày), kết hợp **4 công tắc Terraform** (`enable_nat_gateway`, `enable_alb`, `enable_waf`, `enable_fargate = false`) và **AWS Budgets** kiểm soát trần `200 USD AWS Credit`.
- **Phòng vệ 2 lớp & DevSecOps Zero-Keys:** Chặn SQL Injection/XSS (`HTTP 403`) và Rate Limiting `100 req/phút/IP` (`HTTP 429`); 3 pipeline **GitHub Actions** xác thực bằng **AWS OIDC** (không lưu Access Key tĩnh) và quét lỗ hổng Docker image bằng **Aqua Security Trivy**.

---

## 2. Kiến trúc hệ thống (Serverless + Dual-VPC Multi-AZ)

Hệ thống được triển khai tại vùng **`ap-southeast-1` (Singapore)** theo mô hình **2 nhánh bổ trợ nhau**:

```text
                        [ Người dùng / Trình duyệt ]
                           │         │           │
       1. Xem web & WebP   │         │ 3. PUT    │ 2. Xin Presigned URL
                           ▼         │ (SigV4)   ▼
         ┌──────────────────────┐    │    ┌────────────────────────────┐
         │ Amazon CloudFront    │    │    │ AWS Lambda Function URL    │
         │ cloudmedia.duccloud  │    │    │ cloud-media-studio-api     │
         │ .men (OAC + ACM TLS) │    │    │ (Presigned, SQLi 403, 429) │
         └──────────┬───────────┘    │    └─────────────┬──────────────┘
                    │ OAC GetObject  │                  │ List / Archive / Delete
                    ▼                ▼                  ▼
         ┌─────────────────────────────────────────────────────────────┐
         │ Amazon S3 Bucket (Block Public Access = ON, CORS Enabled)   │
         │ cloud-media-studio-assets-586643076560                      │
         │ Phân vùng: uploads/   |   processed/   |   thumbnails/      │
         └──────────┬──────────────▲────────────────────┬──────────────┘
       4. Event     │              │ 5. Ghi .webp       │ Lifecycle (30d)
       uploads/     ▼              │ & 3 thumbnails     ▼ / CopyObject
         ┌──────────────────────┐  │      ┌────────────────────────────┐
         │ AWS Lambda ARM64     │──┘      │ S3 Glacier / Glacier IR    │
         │ image-processor      │         │ Giảm 84% chi phí lưu trữ   │
         │ (sharp + libvips)    │         └────────────────────────────┘
         └──────────┬───────────┘
                    ▼
         ┌──────────────────────┐         ┌────────────────────────────┐
         │ Amazon CloudWatch    │         │ Nhánh 2: Dual-VPC Multi-AZ │
         │ Realtime Logs        │         │ 10.0.0.0/16 <-> 10.1.0.0/16│
         └──────────────────────┘         │ 6 Subnets + SG-to-SG       │
                                          │ ECS Fargate + ALB + WAFv2  │
                                          │ + RDS (Terraform Flags)    │
                                          └────────────────────────────┘
```

---

## 3. Phân công thành viên (Nhóm 1 — NovaCloud Consulting)

| STT | Họ và tên | MSSV | Vai trò & Phân mảng phụ trách |
| :-: | :--- | :-: | :--- |
| 1 | **Nguyễn Minh Quân** | `24022825` | Kiến trúc giải pháp, Dual-VPC Peering, 6 Subnets Multi-AZ, CloudFront + ACM, Terraform IaC |
| 2 | **Trần Đức Diễn** | `24021407` | Ứng dụng & Serverless — Giao diện Web Studio, 2 hàm Lambda ARM64 (`media_api`, `image_processor` dùng `sharp`), ECS Fargate |
| 3 | **Phạm Thế Hùng** | `24022795` | Dữ liệu & FinOps — S3 Bucket & Lifecycle Glacier, RDS MySQL schema, AWS Budgets ($200), CloudWatch Logs & tối ưu chi phí |
| 4 | **Đỗ Trung Đức** | `23020045` | An toàn thông tin & DevSecOps — IAM PoLP & OIDC Zero-Keys, Security Groups SG-to-SG, WAFv2 / SQLi 403 / Rate-Limit 429, CI/CD Trivy |

---

## 4. Hướng dẫn trải nghiệm, kiểm thử & triển khai

### 4.1. Trải nghiệm trực tiếp trên AWS (không cần cài đặt)
1. Truy cập **[https://cloudmedia.duccloud.men/](https://cloudmedia.duccloud.men/)** (xác nhận nhãn xanh `AWS Serverless Connected`).
2. Vào tab **Upload Media** → chọn một ảnh `.png` / `.jpg` → bấm **Kích Hoạt Lambda Thật Trên AWS S3** để xem luồng Presigned PUT + nén `.webp` + sinh 3 thumbnail realtime.
3. Mở chi tiết một ảnh trong thư viện → bấm **Move to Glacier (FinOps)** để chuyển lớp lưu trữ thật trên S3 sang `GLACIER_IR`.

### 4.2. Chạy bộ kiểm thử nghiệm thu trên AWS thật
Yêu cầu: **Node.js >= 20** (không cần bật server cục bộ, kịch bản gọi trực tiếp AWS Production):

```bash
# 1. Cài đặt dependencies
npm install

# 2. Kiểm thử toàn trình 6 bước (Presigned PUT -> S3 -> Lambda WebP -> 3 Thumbnails -> CDN HTTP 200 -> SQLi 403)
node scripts/verify-live-cloud-pipeline.js

# 3. Kiểm thử chịu tải & giới hạn tần suất (125 requests -> 100 x HTTP 200 OK, 25 x HTTP 429 Too Many Requests)
node tests/run-rate-limit-test.js

# 4. (Tùy chọn) Theo dõi nhật ký Lambda nén ảnh realtime từ CloudWatch
node scripts/realtime-lambda.js watch
```

### 4.3. Kiểm tra & triển khai hạ tầng bằng Terraform (IaC)
Yêu cầu: **Terraform >= 1.5** và AWS CLI đã cấu hình quyền truy cập.

```bash
# Kiểm tra định dạng, cú pháp và đối soát trạng thái với S3 Remote Backend
terraform -chdir=terraform init
terraform -chdir=terraform fmt -check
terraform -chdir=terraform validate
terraform -chdir=terraform plan -lock=false
```

> **Công tắc FinOps (`terraform/terraform.tfvars`):**  
> Ngày thường đặt `enable_nat_gateway = false`, `enable_alb = false`, `enable_waf = false`, `enable_fargate = false` để chi phí chờ ở mức tối thiểu. Khi cần bật nhánh doanh nghiệp chịu tải cao, đổi các biến sang `true` rồi chạy `terraform -chdir=terraform apply`.

### 4.4. Build giao diện & chạy mô phỏng Container cục bộ (tùy chọn)

```bash
# Build giao diện tĩnh vào thư mục dist/ (GitHub Actions tự deploy khi push lên main/mquan)
npm run build

# Hoặc chạy nhánh container 3 tầng (MySQL + Backend Express + Nginx) cục bộ bằng Docker Compose
docker compose up -d --build
# Truy cập http://localhost:8080
```

---

## 5. Cấu trúc kho mã nguồn

```text
cloud-media-studio/
├── .github/workflows/
│   ├── deploy-frontend.yml        # OIDC -> build dist/ -> S3 Sync (--exclude media) -> CloudFront Invalidation
│   ├── ci.yml                     # Kiểm tra cú pháp, build Docker & quét lỗ hổng Aqua Security Trivy
│   └── terraform.yml              # Tự động fmt, validate & plan hạ tầng Terraform
├── backend/
│   ├── lambda/
│   │   ├── media_api/             # Lambda Function URL: Presigned PUT (SigV4), List/Archive/Delete, SQLi 403, Rate 429
│   │   └── image_processor/       # Lambda ARM64 (sharp/libvips): Nén WebP & sinh 3 bản Thumbnail
│   ├── Dockerfile                 # Container Node.js 22 cho nhánh ECS Fargate
│   └── server.js                  # Express API cho nhánh Container / Local
├── db/
│   └── init.sql                   # Schema bảng media_items cho RDS MySQL
├── finops/
│   ├── rbac-matrix.md             # Ma trận phân quyền IAM PoLP cho 4 thành viên
│   └── terraform/                 # S3 Lifecycle Glacier, AWS Budgets ($200), IAM, RDS, DynamoDB, CloudWatch
├── frontend/
│   ├── index.html                 # Giao diện quản trị Cloud Media Studio
│   ├── Dockerfile & nginx.conf    # Cấu hình container frontend (nhánh Docker)
├── scripts/
│   ├── build.js                   # Đóng gói bản build tĩnh dist/
│   ├── verify-live-cloud-pipeline.js  # Kịch bản kiểm thử nghiệm thu 6 bước trên AWS thật
│   └── realtime-lambda.js         # Giám sát CloudWatch Logs của Lambda theo thời gian thực
├── terraform/                     # 16 tệp IaC: Dual-VPC, 6 Subnets, Peering, SG, CloudFront OAC, Lambda, ECS, ALB, WAFv2
├── tests/
│   ├── run-rate-limit-test.js     # Bắn tải 125 req kiểm chứng Rate Limiting 429 trên AWS API
│   └── k6-rate-limit.js           # Kịch bản kiểm thử tải với Grafana k6
├── docker-compose.yml             # Mô phỏng môi trường 3 tầng cục bộ
└── package.json                   # Khai báo script build/deploy
```
