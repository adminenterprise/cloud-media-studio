# HẠ TẦNG MÃ NGUỒN (IaC) — TERRAFORM
## ENTERPRISE CLOUD & DEVSECOPS PLATFORM

> **Phân mảng phụ trách:** Thành viên 1 (Nhóm trưởng — Mạng & IaC)  
> **Trạng thái:** Hoàn thiện 100% các phân hệ Tuần 1 đến Tuần 6 (Đóng gói 1-Click Deployment)  
> **Phiên bản AWS Provider:** `>= 5.0` | **Terraform:** `>= 1.5.0`

---

## 1. Sơ đồ Kiến trúc Mạng Đa Tầng (Enterprise Multi-VPC Architecture)

Hệ thống được thiết kế theo chuẩn **AWS Well-Architected Framework**, áp dụng mô hình **Dual-VPC** (Production VPC và Management/DevSecOps VPC) kết nối qua **VPC Peering**, phân tách 3 tầng cô lập (`3-Tier Multi-AZ`):

```
                                      INTERNET
                                         │
                         ┌───────────────┴───────────────┐
                         ▼                               ▼
                 [Amazon Route 53]              [Amazon CloudFront]
                 (DNS Management)               (Global CDN Cache)
                         │                               │
                         └───────────────┬───────────────┘
                                         ▼
                             ┌───────────────────────┐
                             │     AWS WAFv2 ACL     │ (SQLi, XSS, Rate Limit)
                             └───────────┬───────────┘
                                         ▼
                      [Application Load Balancer (ALB)]
                                         │
┌────────────────────────────────────────┴────────────────────────────────────────┐
│ PRODUCTION VPC (10.0.0.0/16) - ap-southeast-1                                   │
│                                                                                 │
│  [Availability Zone: ap-southeast-1a]        [Availability Zone: ap-southeast-1b]
│                                                                                 │
│  ┌─────────────────────────────────┐        ┌─────────────────────────────────┐ │
│  │ Public Subnet (10.0.1.0/24)     │        │ Public Subnet (10.0.2.0/24)     │ │
│  │ ├── Internet Gateway (IGW)      │        │ └── Dự phòng Multi-AZ ALB       │ │
│  │ └── NAT Gateway (Egress traffic)│        │                                 │ │
│  └────────────────┬────────────────┘        └────────────────┬────────────────┘ │
│                   │                                          │                  │
│  ┌────────────────┴────────────────┐        ┌────────────────┴────────────────┐ │
│  │ Private App Subnet (10.0.10.0/24)        │ Private App Subnet (10.0.11.0/24)│
│  │ [Member 2]: EC2 Auto Scaling,   │        │ [Member 2]: EC2 Auto Scaling,   │ │
│  │             ECS Fargate, EFS    │        │             ECS Fargate         │ │
│  └────────────────┬────────────────┘        └────────────────┬────────────────┘ │
│                   │                                          │                  │
│  ┌────────────────┴────────────────┐        ┌────────────────┴────────────────┐ │
│  │ Private DB Subnet (10.0.20.0/24)│        │ Private DB Subnet (10.0.21.0/24)│ │
│  │ [Member 3]: RDS MySQL / Aurora  │        │ [Member 3]: Standby Replica RDS │ │
│  │             (Cách ly 100%)      │        │             (Cách ly 100%)      │ │
│  └─────────────────────────────────┘        └─────────────────────────────────┘ │
└──────────────────────────┬──────────────────────────────────────────────────────┘
                           │
                 [VPC Peering Connection] (pcx-xxxxxxxxx)
                           │
┌──────────────────────────┴──────────────────────────────────────────────────────┐
│ MANAGEMENT / DEVSECOPS VPC (10.1.0.0/16)                                        │
│                                                                                 │
│  ┌───────────────────────────────────────────────────────────────────────────┐  │
│  │ Management Subnet (10.1.1.0/24)                                           │  │
│  │ ├── Bastion Host (SSH Jump Server an toàn qua Peering)                    │  │
│  │ └── Self-hosted CI/CD Runner / DevOps Management Tools                    │  │
│  └───────────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Danh mục Mã nguồn & Phân hệ Kỹ thuật

| Tập tin `.tf` | Phân hệ đảm nhiệm | Tuần triển khai | Mục đích & Chi tiết kỹ thuật |
| :--- | :--- | :---: | :--- |
| `vpc.tf` | Core Network | Tuần 1 | Khởi tạo Production VPC (`10.0.0.0/16`), bật DNS hostnames/support. |
| `subnets.tf` | Subnets Multi-AZ | Tuần 1 | Tạo 6 subnets trên 2 AZ (2 Public, 2 Private App, 2 Private DB) + DB Subnet Group. |
| `gateways.tf` | Gateway Services | Tuần 1 | Khởi tạo Internet Gateway và NAT Gateway kèm Elastic IP (EIP). |
| `routes.tf` | Tuyến đường mạng | Tuần 1 | Bảng định tuyến Public (ra IGW), Private App (ra NAT GW), Private DB (nội bộ). |
| `security_groups.tf` | Tường lửa ảo SG | Tuần 2 | 5 nhóm Security Groups phân tầng chặt chẽ (ALB, App, DB, EFS, Bastion). |
| `alb.tf` | Cân bằng tải ứng dụng | Tuần 4 | ALB Multi-AZ, Target Group (loại `ip` cho ECS), Listener cổng 80 với Fixed-response 200. |
| `waf.tf` | Tường lửa Web WAFv2 | Tuần 4 | Web ACL gắn trực tiếp ALB: AWS CRS, AWS SQLi Rule, Custom Rate Limiting (100 req/5m). |
| `cloudfront.tf` | Mạng phân phối nội dung | Tuần 3 | Phân phối CDN CloudFront tối ưu hóa caching cho frontend và định tuyến API về ALB. |
| `route53.tf` | Phân giải tên miền DNS | Tuần 3 | Public Hosted Zone và Alias Records trỏ tên miền về CloudFront & ALB. |
| `vpc_peering.tf` | Kết nối Multi-VPC | Tuần 5 | Khởi tạo VPC Management (`10.1.0.0/16`) và Peering thông suốt hai chiều với Production. |
| `variables.tf` | Khai báo biến | Toàn bộ | Khai báo toàn bộ tham số, kiểu dữ liệu, giá trị mặc định và mô tả chi tiết. |
| `terraform.tfvars` | Giá trị cấu hình | Toàn bộ | Tệp cấu hình tham số thực tế của dự án. |
| `outputs.tf` | Tham số bàn giao | Toàn bộ | Xuất hơn 25 tham số kỹ thuật để bàn giao cho Member 2, 3, 4. |

---

## 3. Quy trình Triển khai 1-Click (1-Click Deployment)

Mã nguồn được đóng gói hoàn chỉnh với các kịch bản tự động hóa hỗ trợ cả Windows (PowerShell) và Linux/macOS (Bash).

### Cách 1: Triển khai nhanh bằng Scripts tự động (Khuyên dùng)

#### Trên Windows (PowerShell):
```powershell
# Chạy script tự động kiểm tra cú pháp, format, plan và apply
.\scripts\deploy.ps1

# Hoặc chế độ tự động duyệt (không hỏi xác nhận):
.\scripts\deploy.ps1 -AutoApprove
```

#### Trên Linux / macOS / Git Bash:
```bash
chmod +x scripts/*.sh

# Chạy triển khai
./scripts/deploy.sh

# Hoặc chế độ tự động duyệt:
./scripts/deploy.sh -y
```

### Cách 2: Triển khai thủ công từng lệnh chuẩn Terraform

```bash
cd terraform

# 1. Tạo file cấu hình từ mẫu
cp terraform.tfvars.example terraform.tfvars

# 2. Tải AWS Provider và khởi tạo
terraform init

# 3. Kiểm tra cú pháp và quy chuẩn
terraform fmt -check
terraform validate

# 4. Xem trước kế hoạch triển khai (~25-30 tài nguyên)
terraform plan -out=tfplan

# 5. Áp dụng triển khai lên AWS
terraform apply tfplan

# 6. Xem danh sách thông số bàn giao
terraform output
```

---

## 4. Bảng Bàn Giao Tham Số Kỹ Thuật (Handover Specification)

Sau khi `terraform apply` thành công, Member 1 bàn giao các thông số sau qua lệnh `terraform output`:

| Tên Output | Bên tiếp nhận | Mục đích sử dụng |
| :--- | :---: | :--- |
| `vpc_id` | Toàn nhóm | ID Production VPC để gắn tài nguyên hoặc Peering |
| `public_subnet_ids` | **Member 2** | Subnets đặt Application Load Balancer |
| `private_app_subnet_ids` | **Member 2** | Subnets triển khai EC2 Auto Scaling Group & ECS Fargate |
| `alb_security_group_id` | **Member 2** | Security Group gắn vào Load Balancer |
| `app_security_group_id` | **Member 2** | Security Group gắn vào EC2/ECS (chỉ nhận traffic từ ALB) |
| `alb_target_group_arn` | **Member 2** | Đích đến gắn vào ECS Service / Auto Scaling Group |
| `alb_dns_name` | **Member 2, 4** | Endpoint kiểm thử trực tiếp ứng dụng & kịch bản WAF |
| `private_db_subnet_ids` | **Member 3** | Subnets cách ly triển khai RDS Multi-AZ / Aurora |
| `rds_db_subnet_group_name` | **Member 3** | DB Subnet Group truyền vào khai báo RDS Terraform |
| `db_security_group_id` | **Member 3** | Security Group gắn vào RDS (chỉ nhận cổng 3306 từ App SG) |
| `waf_web_acl_id` / `arn` | **Member 4** | WAF Web ACL bảo vệ ALB để theo dõi CloudWatch |
| `management_vpc_id` | **Member 4** | VPC thứ 2 phục vụ đặt CI/CD Runner / Bastion Host |
| `vpc_peering_connection_id` | Toàn nhóm | Kết nối Peering giữa 2 VPC |

---

## 5. Chiến Lược Tối Ưu Chi Phí (FinOps Safeguards — $200 Budget)

Dự án sử dụng gói tài trợ sinh viên $200 AWS Credit. Để tránh tiêu hao chi phí ngoài ý muốn:

1. **Công tắc bật/tắt NAT Gateway (`enable_nat_gateway`)**:
   - NAT Gateway tiêu tốn ~$0.045/giờ (~$32.4/tháng).
   - Khi chỉ test cấu hình mạng, DNS, WAF hoặc không cần Internet cho Private Subnet, đặt `enable_nat_gateway = false` trong `terraform.tfvars`.
2. **Công tắc bật/tắt ALB & WAF (`enable_alb_and_waf`)**:
   - ALB tốn ~$0.0225/giờ + WAF ($5/tháng + $1/rule).
   - Khi không chạy diễn tập demo, có thể tạm thời tắt bằng cách cấu hình flag này thành `false`.
3. **Thu hồi toàn bộ hạ tầng bằng 1 lệnh (Clean-Up)**:
   Sau khi hoàn tất buổi diễn tập demo hoặc thực hành:
   ```powershell
   # Trên Windows
   .\scripts\destroy.ps1

   # Trên Linux/macOS
   ./scripts/destroy.sh
   ```

---

## 6. Hướng Dẫn Xử Lý Sự Cố Thường Gặp (Troubleshooting)

- **Lỗi `AccessDenied` khi chạy Terraform**: Kiểm tra lại quyền của IAM User. Đảm bảo user có quyền quản trị VPC, EC2, WAF, CloudFront, Route53.
- **Lỗi `InvalidSubnetID.NotFound`**: Đảm bảo các subnets đã được tạo thành công trước khi gắn vào ALB hoặc RDS.
- **ALB trả về `503 Service Temporarily Unavailable`**: Do Member 2 chưa cắm instance vào Target Group hoặc Health Check `/health` đang fail. Kiểm tra trạng thái target trong AWS Console.
- **WAF chặn `403 Forbidden` đối với request bình thường**: Kiểm tra IP có gửi quá 100 requests trong 5 phút không (Rate Limit), hoặc User-Agent/payload có trùng mẫu CRS không.
