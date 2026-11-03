# 📋 SECURITY GROUPS — QUY TẮC MỞ CỔNG (FIREWALL RULES DOCUMENTATION)

> **Dự án**: Cloud Media Studio Platform  
> **Tuần 2**: Tầng Lưu Trữ, Dữ Liệu & Máy Chủ Tính Toán  
> **Nguyên tắc**: Principle of Least Privilege + SG-to-SG Reference  
> **Cập nhật**: 12/10/2026

---

## 1. TỔNG QUAN KIẾN TRÚC SECURITY GROUPS

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          PRODUCTION VPC (10.0.0.0/16)                  │
│                                                                       │
│  ┌─────────────── PUBLIC SUBNETS ──────────────┐                      │
│  │                                              │                      │
│  │  ┌──────────┐         ┌──────────────┐       │                      │
│  │  │ Bastion  │         │     ALB      │       │                      │
│  │  │   SG     │         │     SG       │       │                      │
│  │  │ SSH:22   │         │ HTTP:80      │       │                      │
│  │  │ Admin IP │         │ HTTPS:443    │       │                      │
│  │  └────┬─────┘         └──────┬───────┘       │                      │
│  └───────┼──────────────────────┼───────────────┘                      │
│          │ SSH:22               │ App Port:3000                        │
│  ┌───────┼──────────────────────┼───────────────┐                      │
│  │       ▼     PRIVATE-APP SUBNETS              │                      │
│  │  ┌──────────────────┐   ┌──────────────┐     │                      │
│  │  │   App Server SG  │──►│   EFS SG     │     │                      │
│  │  │   Port:3000      │   │   NFS:2049   │     │                      │
│  │  └────────┬─────────┘   └──────────────┘     │                      │
│  └───────────┼──────────────────────────────────┘                      │
│              │ MySQL:3306                                              │
│  ┌───────────┼──────────────────────────────────┐                      │
│  │           ▼     PRIVATE-DB SUBNETS (ISOLATED)│                      │
│  │  ┌──────────────────┐                        │                      │
│  │  │  Database SG     │   ← NO EGRESS          │                      │
│  │  │  MySQL:3306      │   ← FULLY ISOLATED     │                      │
│  │  └──────────────────┘                        │                      │
│  └──────────────────────────────────────────────┘                      │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. BẢNG TỔNG HỢP QUY TẮC (RULES MATRIX)

### 2.1 ALB Security Group (`cloud-media-studio-alb-sg`)

| Hướng | Giao thức | Port | Nguồn/Đích | Lý do |
|:---|:---|:---|:---|:---|
| **INGRESS** | TCP | 80 | `0.0.0.0/0` | Cho phép HTTP từ Internet (redirect HTTPS) |
| **INGRESS** | TCP | 443 | `0.0.0.0/0` | Cho phép HTTPS từ Internet |
| **EGRESS** | TCP | 3000 | App Server SG | Chuyển tiếp traffic đến backend |

### 2.2 App Server Security Group (`cloud-media-studio-app-sg`)

| Hướng | Giao thức | Port | Nguồn/Đích | Lý do |
|:---|:---|:---|:---|:---|
| **INGRESS** | TCP | 3000 | ALB SG | Nhận traffic từ Load Balancer |
| **INGRESS** | TCP | 22 | Bastion SG | SSH debug từ Bastion Host |
| **EGRESS** | TCP | 3306 | Database SG | Kết nối MySQL/Aurora |
| **EGRESS** | TCP | 2049 | EFS SG | Mount ổ đĩa chia sẻ NFS |
| **EGRESS** | TCP | 443 | `0.0.0.0/0` | Pull packages, Docker images |
| **EGRESS** | UDP | 53 | `0.0.0.0/0` | DNS resolution |
| **EGRESS** | TCP | 53 | `0.0.0.0/0` | DNS resolution (TCP fallback) |

### 2.3 Database Security Group (`cloud-media-studio-db-sg`)

| Hướng | Giao thức | Port | Nguồn/Đích | Lý do |
|:---|:---|:---|:---|:---|
| **INGRESS** | TCP | 3306 | App Server SG | Chỉ App Server mới được kết nối DB |
| **EGRESS** | — | — | — | **KHÔNG CÓ** — Cách ly hoàn toàn |

> ⚠️ **Lưu ý bảo mật**: Database SG không có egress rule. Đây là thiết kế có chủ đích theo chuẩn Enterprise DevSecOps — tầng dữ liệu không bao giờ cần gọi ra Internet.

### 2.4 EFS Security Group (`cloud-media-studio-efs-sg`)

| Hướng | Giao thức | Port | Nguồn/Đích | Lý do |
|:---|:---|:---|:---|:---|
| **INGRESS** | TCP | 2049 | App Server SG | Cho phép NFS mount từ App Server |
| **EGRESS** | — | — | — | **KHÔNG CÓ** — Chỉ phục vụ storage |

### 2.5 Bastion Host Security Group (`cloud-media-studio-bastion-sg`)

| Hướng | Giao thức | Port | Nguồn/Đích | Lý do |
|:---|:---|:---|:---|:---|
| **INGRESS** | TCP | 22 | Admin IP (variable) | SSH giới hạn IP quản trị viên |
| **EGRESS** | TCP | 22 | App Server SG | Jump vào Private Subnet |
| **EGRESS** | TCP | 443 | `0.0.0.0/0` | Cập nhật hệ thống, tải công cụ |

> ⚠️ **Quan trọng**: Biến `admin_ip` hiện đặt `0.0.0.0/0` (mở toàn bộ). **Bắt buộc thay bằng IP thật** trước khi deploy production (ví dụ: `203.0.113.10/32`).

---

## 3. NGUYÊN TẮC BẢO MẬT ÁP DỤNG

| # | Nguyên tắc | Cách áp dụng |
|---|---|---|
| 1 | **Principle of Least Privilege** | Chỉ mở đúng port cần thiết, không mở dải port |
| 2 | **SG-to-SG Reference** | Traffic nội bộ tham chiếu Security Group ID thay vì CIDR → tự động cập nhật khi thay đổi IP |
| 3 | **Default Deny Egress** | Không dùng `0.0.0.0/0` cho egress trừ HTTPS/DNS cần thiết. DB và EFS không có egress |
| 4 | **Defense in Depth** | Nhiều lớp bảo vệ: SG → NACL → WAF (Tuần 4) → CloudFront → Route 53 |
| 5 | **Admin IP Restriction** | Bastion SSH giới hạn theo IP cụ thể, không mở rộng |

---

## 4. BÀN GIAO CHO CÁC THÀNH VIÊN

| Output | Thành viên | Mục đích sử dụng |
|---|---|---|
| `alb_security_group_id` | Member 2 | Gắn vào Application Load Balancer |
| `app_security_group_id` | Member 2 | Gắn vào EC2 ASG / ECS Fargate Tasks |
| `efs_security_group_id` | Member 2 | Gắn vào EFS Mount Targets |
| `db_security_group_id` | Member 3 | Gắn vào RDS MySQL / Aurora Serverless |
| `bastion_security_group_id` | Admin | Gắn vào Bastion EC2 Instance |

Các thành viên chỉ cần tham chiếu output bằng:
```hcl
# Ví dụ: Member 2 tham chiếu SG cho ALB
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "enterprise-devsecops-tfstate-586643076560"
    key    = "network/terraform.tfstate"
    region = "ap-southeast-1"
  }
}

# Sử dụng
security_groups = [data.terraform_remote_state.network.outputs.alb_security_group_id]
```
