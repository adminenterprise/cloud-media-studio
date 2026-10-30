# HẠ TẦNG MÃ NGUỒN (IaC) — TERRAFORM

> **Phân mảng:** Thành viên 1 (Nhóm trưởng — Mạng & IaC)  
> **Mục tiêu Tuần 1:** Production VPC Multi-AZ, 6 Subnets (Public, Private App, Private DB), Internet Gateway, NAT Gateway và Route Tables.

---

## 1. Sơ đồ phân tầng mạng (Network Architecture)

```
PRODUCTION VPC: 10.0.0.0/16 (ap-southeast-1)
├── AZ-a (ap-southeast-1a)
│   ├── Public Subnet:        10.0.1.0/24   [Gắn IGW, ALB, NAT GW]
│   ├── Private App Subnet:   10.0.10.0/24  [Egress qua NAT GW - EC2, ECS Fargate]
│   └── Private DB Subnet:    10.0.20.0/24  [Cách ly 100% - RDS Aurora, MySQL]
│
├── AZ-b (ap-southeast-1b)
│   ├── Public Subnet:        10.0.2.0/24   [Gắn IGW, ALB]
│   ├── Private App Subnet:   10.0.11.0/24  [Egress qua NAT GW - EC2, ECS Fargate]
│   └── Private DB Subnet:    10.0.21.0/24  [Cách ly 100% - RDS Aurora, MySQL]
│
└── Quản trị Egress & Tuyến đường:
    ├── Internet Gateway (1 bộ): Định tuyến cho Public Subnets (0.0.0.0/0)
    ├── NAT Gateway (1 bộ FinOps): Đặt tại AZ-a, cấp quyền truy cập ra ngoài cho cả 2 Private App Subnets
    └── RDS DB Subnet Group: Sẵn sàng phục vụ triển khai Multi-AZ cho Member 3
```

---

## 2. Quy trình Thực thi (Execution Steps)

### Bước 1: Chuẩn bị thông tin xác thực AWS
Đảm bảo bạn đã cấu hình AWS CLI với quyền hợp lệ:
```bash
aws configure
# Hoặc thiết lập biến môi trường AWS_ACCESS_KEY_ID và AWS_SECRET_ACCESS_KEY
```

### Bước 2: Khởi tạo & Kiểm thử cú pháp
```bash
cd terraform

# Tạo file tfvars từ file mẫu
cp terraform.tfvars.example terraform.tfvars

# Khởi tạo Terraform & tải AWS Provider
terraform init

# Kiểm tra cú pháp mã nguồn
terraform validate

# Xem trước kế hoạch triển khai tài nguyên (~18 resources)
terraform plan
```

### Bước 3: Triển khai hạ tầng
```bash
terraform apply
```

### Bước 4: Lấy thông số bàn giao cho các thành viên
```bash
terraform output
```

### Bước 5: Tiết kiệm chi phí khi không sử dụng (FinOps)
Khi kết thúc buổi thực hành/kiểm thử, để không bị trừ tiền NAT Gateway ($0.045/giờ):
* **Cách 1 (Tắt riêng NAT Gateway):** Sửa trong `terraform.tfvars`: `enable_nat_gateway = false`, sau đó chạy `terraform apply`.
* **Cách 2 (Hủy toàn bộ nếu không cần giữ môi trường):** `terraform destroy`.

---

## 3. Bảng Bàn giao Tham số (Handover Specification)

| Tham số Output | Thành viên tiếp nhận | Mục đích sử dụng |
|---|---|---|
| `vpc_id` | Toàn bộ nhóm | Gắn Security Groups, VPC Peering, Endpoints |
| `public_subnet_ids` | **Member 2** | Triển khai Application Load Balancer (ALB) |
| `private_app_subnet_ids` | **Member 2** | Triển khai EC2 Auto Scaling Group, ECS Fargate Services |
| `private_db_subnet_ids` | **Member 3** | Triển khai cơ sở dữ liệu quan hệ RDS MySQL / Aurora Serverless |
| `rds_db_subnet_group_name` | **Member 3** | Truyền thẳng vào thuộc tính `db_subnet_group_name` của RDS |
