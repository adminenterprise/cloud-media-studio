# HƯỚNG DẪN TRIỂN KHAI FINOPS & IAM — TUẦN 1

> **Phân mảng:** Thành viên 3 (Dữ liệu & FinOps — Phạm Thế Hùng)  
> **Mục tiêu Tuần 1:** Cấu hình IAM User cho 4 thành viên theo nguyên tắc đặc quyền tối thiểu (`Least Privilege`), thiết lập AWS Budgets cảnh báo $20/$50 gửi email tự động kiểm soát gói ngân sách sinh viên $200.

---

## 1. TỔNG QUAN KẾT QUẢ BÀN GIAO (DELIVERABLES)

Thành viên 3 đã đóng gói đầy đủ giải pháp cho Tuần 1 với 3 hình thức triển khai linh hoạt:

1. **Hạ tầng dưới dạng mã nguồn (IaC Terraform)**: Nằm trong thư mục [`finops/terraform/`](file:///c:/Users/Pham%20The%20Hung/ENTERPRISE-CLOUD-DEVSECOPS-PLATFORM/finops/terraform) — tự động hóa 100% 4 IAM Groups, 4 IAM Users, chính sách mật khẩu, 5 IAM Policies và cấu hình AWS Budgets.
2. **Kịch bản tự động hóa AWS CLI**: Nằm trong thư mục [`finops/scripts/`](file:///c:/Users/Pham%20The%20Hung/ENTERPRISE-CLOUD-DEVSECOPS-PLATFORM/finops/scripts) — hỗ trợ cả PowerShell (`.ps1`) và Bash (`.sh`) để khởi tạo nhanh qua terminal.
3. **Bảng ma trận phân quyền (RBAC Matrix)**: Nằm tại [`finops/rbac-matrix.md`](file:///c:/Users/Pham%20The%20Hung/ENTERPRISE-CLOUD-DEVSECOPS-PLATFORM/finops/rbac-matrix.md) — tài liệu chuẩn doanh nghiệp dùng để đưa vào Chương 5 của Báo cáo đồ án.
4. **Hướng dẫn trực quan AWS Console**: Chi tiết từng bước bên dưới giúp thực hiện trực tiếp trên trình duyệt và chụp ảnh minh chứng nộp báo cáo tuần 1.

---

## 2. PHƯƠNG PHÁP 1: TRIỂN KHAI QUA TERRAFORM (KHUYẾN NGHỊ ENTERPRISE)

### Bước 1: Chuẩn bị tệp cấu hình biến
```bash
cd finops/terraform

# Sao chép tệp mẫu
cp terraform.tfvars.example terraform.tfvars
```
Mở tệp `terraform.tfvars` và điền danh sách email thực tế nhận cảnh báo:
```hcl
notification_emails = [
  "minhquan10092006@gmail.com",
  "hungpham@example.com"
]
```

### Bước 2: Khởi tạo và triển khai
```bash
# Tải AWS Provider
terraform init

# Kiểm tra cú pháp và tính toán kế hoạch (~16 resources)
terraform plan

# Áp dụng triển khai lên AWS
terraform apply -auto-approve
```

### Bước 3: Xem kết quả bàn giao
```bash
terraform output
```

---

## 3. PHƯƠNG PHÁP 2: THỰC HIỆN TRÊN AWS MANAGEMENT CONSOLE (ĐỂ CHỤP ẢNH MINH CHỨNG)

### PHẦN A: THIẾT LẬP AWS BUDGETS CẢNH BÁO $20 / $50

1. **Truy cập dịch vụ**:
   - Đăng nhập vào [AWS Management Console](https://console.aws.amazon.com/).
   - Tại thanh tìm kiếm trên cùng, gõ **AWS Budgets** và chọn dịch vụ.
2. **Khởi tạo ngân sách**:
   - Nhấn nút màu cam **Create budget**.
   - Tại mục *Budget setup*: Chọn **Customize (advanced)** -> Chọn **Cost budget** -> Nhấn **Next**.
3. **Điền thông số ngân sách**:
   - **Budget name**: `enterprise-cloud-student-budget-200usd`
   - **Period**: Chọn `Monthly` (Hàng tháng)
   - **Budget renewal type**: `Recurring budget`
   - **Start month**: Tháng hiện tại
   - **Budgeting method**: `Fixed`
   - **Enter your budgeted amount ($)**: Nhập `200`
   - Nhấn **Next**.
4. **Thiết lập 2 ngưỡng cảnh báo bắt buộc (Alert Thresholds)**:
   - **Cảnh báo 1 ($20 USD)**:
     * Nhấn **Add an alert threshold**.
     * *Set alert threshold*: Chọn `Absolute amount` và nhập `20` (hoặc chọn `Percentage` nhập `10%`).
     * *Trigger*: Chọn **Actual** (chi tiêu thực tế chạm mốc).
     * *Email recipients*: Nhập email nhóm (ví dụ: `minhquan10092006@gmail.com`).
   - **Cảnh báo 2 ($50 USD - Báo động khẩn cấp)**:
     * Nhấn **Add an alert threshold** thứ hai.
     * *Set alert threshold*: Chọn `Absolute amount` và nhập `50` (hoặc `Percentage` nhập `25%`).
     * *Trigger*: Chọn **Actual**.
     * *Email recipients*: Nhập email nhóm.
   - *(Tùy chọn khuyến nghị)*: Thêm Cảnh báo 3 với Trigger là **Forecasted** (Dự báo chạm 80% / $160).
5. **Hoàn tất & Chụp ảnh minh chứng**:
   - Nhấn **Next** -> Bỏ qua phần Actions -> Nhấn **Next** -> Nhấn **Create budget**.
   - 📸 **ẢNH MINH CHỨNG 1**: Chụp ảnh màn hình danh sách AWS Budgets hiển thị rõ tên `enterprise-cloud-student-budget-200usd`, hạn mức `$200.00` và 2 alert thresholds `$20` & `$50`.

---

### PHẦN B: CẤU HÌNH 4 TÀI KHOẢN IAM THEO NGUYÊN TẮC LEAST PRIVILEGE

1. **Bật chính sách mật khẩu mạnh (Password Policy)**:
   - Vào dịch vụ **IAM** -> Menu trái chọn **Account settings**.
   - Mục *Password policy*: Nhấn **Edit** -> Đặt độ dài tối thiểu 12 ký tự, tích chọn đủ chữ hoa, thường, số, ký tự đặc biệt, cho phép người dùng tự đổi mật khẩu.
2. **Tạo 4 IAM User Groups**:
   - Menu trái chọn **User groups** -> Nhấn **Create group**.
   - Tạo lần lượt 4 nhóm:
     1. `Network-IaC-Group` (Member 1)
     2. `Compute-Container-Group` (Member 2)
     3. `Data-FinOps-Group` (Member 3)
     4. `Security-DevSecOps-Group` (Member 4)
3. **Tạo và Gán Chính sách (Policies)**:
   - Menu trái chọn **Policies** -> Nhấn **Create policy** -> Chọn tab **JSON**.
   - Lần lượt dán nội dung từ các tệp cấu hình chuẩn bị sẵn trong thư mục [`finops/scripts/configs/`](file:///c:/Users/Pham%20The%20Hung/ENTERPRISE-CLOUD-DEVSECOPS-PLATFORM/finops/scripts/configs):
     * [`policy_common_base.json`](file:///c:/Users/Pham%20The%20Hung/ENTERPRISE-CLOUD-DEVSECOPS-PLATFORM/finops/scripts/configs/policy_common_base.json) -> Gán vào **cả 4 nhóm**.
     * [`policy_member1_network.json`](file:///c:/Users/Pham%20The%20Hung/ENTERPRISE-CLOUD-DEVSECOPS-PLATFORM/finops/scripts/configs/policy_member1_network.json) -> Gán vào `Network-IaC-Group`.
     * [`policy_member2_compute.json`](file:///c:/Users/Pham%20The%20Hung/ENTERPRISE-CLOUD-DEVSECOPS-PLATFORM/finops/scripts/configs/policy_member2_compute.json) -> Gán vào `Compute-Container-Group`.
     * [`policy_member3_data.json`](file:///c:/Users/Pham%20The%20Hung/ENTERPRISE-CLOUD-DEVSECOPS-PLATFORM/finops/scripts/configs/policy_member3_data.json) -> Gán vào `Data-FinOps-Group`.
     * [`policy_member4_security.json`](file:///c:/Users/Pham%20The%20Hung/ENTERPRISE-CLOUD-DEVSECOPS-PLATFORM/finops/scripts/configs/policy_member4_security.json) -> Gán vào `Security-DevSecOps-Group`.
4. **Tạo 4 người dùng (Users) và đưa vào nhóm**:
   - Menu trái chọn **Users** -> Nhấn **Create user**.
   - Tạo từng user và tích chọn đưa vào nhóm tương ứng:
     * `member1-network-iac` -> thuộc `Network-IaC-Group`
     * `member2-compute-container` -> thuộc `Compute-Container-Group`
     * `member3-data-finops` -> thuộc `Data-FinOps-Group`
     * `member4-security-devsecops` -> thuộc `Security-DevSecOps-Group`
   - Cấp quyền đăng nhập AWS Console: Chọn **Provide user access to the AWS Management Console** -> Đặt mật khẩu ban đầu -> Bắt buộc đổi mật khẩu ở lần đăng nhập đầu tiên (*User must create a new password at next sign-in*).
5. **Hoàn tất & Chụp ảnh minh chứng**:
   - 📸 **ẢNH MINH CHỨNG 2**: Chụp ảnh màn hình danh sách **Users** trong IAM Console hiển thị đủ 4 tài khoản phân nhóm rõ ràng.
   - 📸 **ẢNH MINH CHỨNG 3**: Chụp ảnh màn hình chi tiết 1 User (ví dụ: `member3-data-finops`) hiển thị tab **Permissions policies** tuân thủ Least Privilege.

---

## 4. PHƯƠNG PHÁP 3: TRIỂN KHAI TỰ ĐỘNG BẰNG AWS CLI

Nếu đã cài đặt `aws` CLI trên máy tính cá nhân và cấu hình `aws configure`:

### Chạy bằng PowerShell (Windows):
```powershell
cd finops/scripts

# 1. Khởi tạo AWS Budgets
.\setup_aws_budgets.ps1 -Email "minhquan10092006@gmail.com"

# 2. Khởi tạo 4 IAM Users, Groups và gán Policies
.\setup_iam_users.ps1
```

### Chạy bằng Bash (Linux / macOS / Git Bash):
```bash
cd finops/scripts
chmod +x *.sh

# 1. Khởi tạo AWS Budgets
./setup_aws_budgets.sh "minhquan10092006@gmail.com"

# 2. Khởi tạo IAM Users & Groups
./setup_iam_users.sh
```

---

## 5. DANH MỤC ẢNH MINH CHỨNG HOÀN THÀNH TUẦN 1 (DELIVERABLE CHECKLIST)

Khi nộp báo cáo tiến độ Tuần 1 cho Nhóm trưởng và Giảng viên, Thành viên 3 chỉ cần chuẩn bị 3 bức ảnh minh chứng sau:

| STT | Tên ảnh minh chứng | Nội dung cần thể hiện trên ảnh | Đánh giá đạt chuẩn |
| :---: | :--- | :--- | :---: |
| **01** | `aws-budgets-200usd-alerts.png` | Giao diện AWS Budgets có ngân sách $200, 2 ngưỡng cảnh báo $20 (10%) và $50 (25%) kèm email người nhận | 🟢 Đạt chuẩn FinOps |
| **02** | `iam-users-list.png` | Bảng danh sách 4 Users trên IAM Console (`member1`, `member2`, `member3`, `member4`) được gán đúng 4 Groups | 🟢 Đạt chuẩn PoLP |
| **03** | `iam-group-least-privilege-policy.png` | Chi tiết quyền Policy được gắn cho nhóm chuyên mảng (không dùng quyền `AdministratorAccess`) | 🟢 Đạt chuẩn Enterprise |

---

# HƯỚNG DẪN TRIỂN KHAI TUẦN 2: RDS MYSQL & S3 BUCKET

> **Mục tiêu Tuần 2:** Khởi tạo Amazon RDS MySQL (db.t3.micro) trong Private DB Subnet Multi-AZ; tạo S3 Bucket lưu trữ tài nguyên tĩnh với mã hóa SSE-S3.

---

## 6. TỔNG QUAN DELIVERABLES TUẦN 2

| Deliverable | Mô tả | Trạng thái |
| :--- | :--- | :---: |
| `finops/terraform/rds.tf` | RDS MySQL db.t3.micro + Security Group + Parameter Group (UTF8MB4) + Enhanced Monitoring | ✅ |
| `finops/terraform/s3.tf` | S3 Bucket + SSE-S3 + Block Public Access + Versioning + CORS + Folder structure | ✅ |
| `finops/terraform/variables.tf` | Thêm biến cấu hình RDS (vpc_id, subnet, instance class, password...) | ✅ |
| `finops/terraform/outputs.tf` | Thêm outputs bàn giao: RDS endpoint, S3 bucket name cho Member 2 & 4 | ✅ |
| `finops/scripts/stop_rds.ps1` | Script PowerShell stop/start/status RDS (FinOps tiết kiệm credit) | ✅ |
| `finops/scripts/stop_rds.sh` | Script Bash stop/start/status RDS | ✅ |

---

## 7. TRIỂN KHAI QUA TERRAFORM

### Bước 1: Lấy thông số từ Member 1 (Đã hoàn thành Tuần 2)

Lấy các giá trị VPC, Subnet Group và Database Security Group từ module mạng của Member 1:
```bash
cd terraform/
terraform output vpc_id
terraform output rds_db_subnet_group_name
terraform output db_security_group_id
```

### Bước 2: Cập nhật terraform.tfvars

Mở tệp `finops/terraform/terraform.tfvars` và điền giá trị thực nhận từ Member 1:
```hcl
# Nhận bàn giao từ Member 1
vpc_id                   = "vpc-0abc123def456"
rds_db_subnet_group_name = "enterprise-cloud-devsecops-db-subnet-group"
db_security_group_id     = "sg-0abc123def456"  # SG chuẩn SG-to-SG của Member 1 (db-sg)

# Cấu hình RDS (khớp với appdb trong backend/server.js của Member 2)
rds_db_name         = "appdb"
rds_master_username = "admin"
rds_master_password = "YourStr0ng!P@ssw0rd#2026"
```

### Bước 3: Khởi tạo và triển khai
```bash
cd finops/terraform

# Tải provider (nếu chưa init)
terraform init

# Xem kế hoạch triển khai (~10-15 resources mới)
terraform plan

# Áp dụng triển khai lên AWS
terraform apply -auto-approve
```

### Bước 4: Xem kết quả bàn giao
```bash
# Xem tất cả outputs
terraform output

# Lấy endpoint RDS để bàn giao cho Member 2
terraform output rds_endpoint

# Lấy tên S3 Bucket
terraform output s3_static_assets_bucket
```

---

## 8. QUẢN LÝ RDS TIẾT KIỆM CHI PHÍ (FINOPS)

> ⚠️ **QUAN TRỌNG**: RDS db.t3.micro tốn ~$0.018/giờ (~$0.43/ngày). Nhớ **STOP** khi không dùng!

### PowerShell (Windows):
```powershell
cd finops/scripts

# Tắt RDS khi xong việc
.\stop_rds.ps1 -Action stop

# Bật RDS khi cần test
.\stop_rds.ps1 -Action start

# Kiểm tra trạng thái
.\stop_rds.ps1 -Action status
```

### Bash (Linux/macOS/Git Bash):
```bash
cd finops/scripts
chmod +x stop_rds.sh

./stop_rds.sh stop     # Tắt RDS
./stop_rds.sh start    # Bật RDS
./stop_rds.sh status   # Kiểm tra trạng thái
```

> **Lưu ý:** AWS tự động bật lại RDS sau 7 ngày dừng. Nếu không cần dùng lâu hơn, cần lên lịch stop lại.

---

## 9. NẠP DỮ LIỆU KHỞI TẠO (INIT.SQL) CHO MEMBER 2

Sau khi RDS ở trạng thái `Available`, Member 3 thực hiện nạp schema từ file [`db/init.sql`](file:///c:/Users/Pham%20The%20Hung/ENTERPRISE-CLOUD-DEVSECOPS-PLATFORM/db/init.sql) để Member 2 (Backend NodeJS) có thể truy vấn ngay:

### Cách 1: Sử dụng Script tự động (Khuyên dùng)
```powershell
# PowerShell:
.\finops\scripts\init_db.ps1 -Host "rds-endpoint" -Password "YourPassword"
```
```bash
# Bash:
./finops/scripts/init_db.sh <rds-endpoint> <password>
```

### Cách 2: Chạy lệnh trực tiếp qua MySQL CLI hoặc Docker
```bash
# Chạy trực tiếp nếu máy đã cài MySQL client
mysql -h <rds-endpoint> -P 3306 -u admin -p appdb < db/init.sql

# Hoặc chạy thông qua Docker Container
docker run --rm -v "${PWD}/db/init.sql:/init.sql" mysql:8.0 \
  mysql -h <rds-endpoint> -P 3306 -u admin -p'YourPassword' appdb < /init.sql
```

---

## 10. DANH MỤC ẢNH MINH CHỨNG TUẦN 2 (DELIVERABLE CHECKLIST)

| STT | Tên ảnh minh chứng | Nội dung cần thể hiện trên ảnh | Đánh giá đạt chuẩn |
| :---: | :--- | :--- | :---: |
| **01** | `rds-mysql-available.png` | RDS Console: Instance `Available`, db.t3.micro, Private subnet, Encrypted | 🟢 Đạt chuẩn Enterprise |
| **02** | `rds-security-group-rules.png` | Security Group: Inbound chỉ port 3306 từ App Subnets (10.0.10.0/24, 10.0.11.0/24) | 🟢 Đạt chuẩn Least Privilege |
| **03** | `s3-bucket-sse-s3-enabled.png` | S3 Console: Default encryption = SSE-S3 (AES256) | 🟢 Đạt chuẩn Encryption |
| **04** | `s3-block-public-access.png` | S3 Console: Block all public access = ON (4/4 tích) | 🟢 Đạt chuẩn Security |

---

# HƯỚNG DẪN TRIỂN KHAI TUẦN 3: DYNAMODB & S3 GLACIER LIFECYCLE

> **Phân mảng:** Thành viên 3 (Dữ liệu & FinOps — Phạm Thế Hùng)  
> **Mục tiêu Tuần 3:**  
> 1. Khởi tạo cơ sở dữ liệu phi quan hệ **Amazon DynamoDB** lưu trữ User Sessions (phiên làm việc) và Shopping Cart (giỏ hàng tạm thời), kích hoạt Time-To-Live (TTL) tự động giải phóng dữ liệu hết hạn miễn phí.  
> 2. Thiết lập **S3 Lifecycle Configuration** tự động chuyển tài liệu cũ sang **S3 Glacier** sau 30 ngày và dọn dẹp các phiên bản cũ / upload dở dang để tối ưu chi phí lưu trữ dài hạn (>84% chi phí).

---

## 11. TỔNG QUAN DELIVERABLES TUẦN 3

Thành viên 3 bàn giao gói giải pháp kỹ thuật hoàn chỉnh cho Tuần 3 bao gồm:

| Deliverable | Vị trí tệp | Mô tả kỹ thuật | Trạng thái |
| :--- | :--- | :--- | :---: |
| **DynamoDB IaC** | [`finops/terraform/dynamodb.tf`](file:///c:/Users/Pham%20The%20Hung/ENTERPRISE-CLOUD-DEVSECOPS-PLATFORM/finops/terraform/dynamodb.tf) | 2 bảng: `user-sessions` (PK `sessionId`, GSI `userId`, TTL `expiresAt`) & `cart` (PK `userId`, SK `itemId`, TTL `expiresAt`), chuẩn `PAY_PER_REQUEST` | ✅ |
| **S3 Lifecycle IaC** | [`finops/terraform/s3.tf`](file:///c:/Users/Pham%20The%20Hung/ENTERPRISE-CLOUD-DEVSECOPS-PLATFORM/finops/terraform/s3.tf) | 4 quy tắc Lifecycle: Chuyển `uploads/` và `documents/` sang Glacier sau 30 ngày, chuyển noncurrent versions sang Glacier và expire sau 90 ngày, hủy multipart sau 7 ngày | ✅ |
| **Variables & Outputs** | [`finops/terraform/variables.tf`](file:///c:/Users/Pham%20The%20Hung/ENTERPRISE-CLOUD-DEVSECOPS-PLATFORM/finops/terraform/variables.tf), [`outputs.tf`](file:///c:/Users/Pham%20The%20Hung/ENTERPRISE-CLOUD-DEVSECOPS-PLATFORM/finops/terraform/outputs.tf) | Cấu hình tham số và xuất thông tin Table Name, Table ARN bàn giao cho Member 2 & 4 | ✅ |
| **IAM Policy Update** | [`finops/terraform/iam_policies.tf`](file:///c:/Users/Pham%20The%20Hung/ENTERPRISE-CLOUD-DEVSECOPS-PLATFORM/finops/terraform/iam_policies.tf) | Bổ sung quyền Least Privilege cho ứng dụng backend (Member 2) đọc/ghi session và cart | ✅ |
| **Test Scripts CLI** | [`finops/scripts/test_dynamodb.ps1`](file:///c:/Users/Pham%20The%20Hung/ENTERPRISE-CLOUD-DEVSECOPS-PLATFORM/finops/scripts/test_dynamodb.ps1), [`test_dynamodb.sh`](file:///c:/Users/Pham%20The%20Hung/ENTERPRISE-CLOUD-DEVSECOPS-PLATFORM/finops/scripts/test_dynamodb.sh) | Script kiểm thử tự động: kiểm tra trạng thái bảng, ghi/đọc CRUD, kiểm tra TTL và S3 Lifecycle qua terminal | ✅ |
| **Dữ liệu mẫu JSON** | [`finops/scripts/configs/dynamodb_sample_*.json`](file:///c:/Users/Pham%20The%20Hung/ENTERPRISE-CLOUD-DEVSECOPS-PLATFORM/finops/scripts/configs) | Payload mẫu chuẩn format DynamoDB AttributeValue dùng cho test và demo bảo vệ | ✅ |

---

## 12. PHƯƠNG PHÁP 1: TRIỂN KHAI QUA TERRAFORM (ENTERPRISE STANDARD)

### Bước 1: Kiểm tra cấu hình và kế hoạch triển khai
```bash
cd finops/terraform

# Kiểm tra cú pháp HCL
terraform validate

# Tính toán các tài nguyên bổ sung (~3-5 resources mới: 2 DynamoDB tables + S3 Lifecycle config)
terraform plan
```

### Bước 2: Áp dụng triển khai lên AWS
```bash
terraform apply -auto-approve
```

### Bước 3: Xem các thông số bàn giao liên thành viên
```bash
# Xem danh sách bảng và ARN
terraform output dynamodb_user_sessions_table_name
terraform output dynamodb_user_sessions_table_arn
terraform output dynamodb_cart_table_name
terraform output dynamodb_cart_table_arn

# Xem trạng thái S3 Lifecycle
terraform output s3_lifecycle_status
```

> **Giao diện bàn giao:**
> - Bàn giao cho **Member 2 (Backend)**: Đặt biến môi trường `DYNAMODB_TABLE_SESSION=enterprise-cloud-devsecops-user-sessions` và `DYNAMODB_TABLE_CART=enterprise-cloud-devsecops-cart`.
> - Bàn giao cho **Member 4 (DevSecOps)**: Sử dụng Table ARNs để gắn vào `Task Role` của ECS Container Task Definition.

---

## 13. PHƯƠNG PHÁP 2: THỰC HIỆN TRÊN AWS MANAGEMENT CONSOLE (ĐỂ CHỤP ẢNH MINH CHỨNG)

### PHẦN A: KHỞI TẠO DYNAMODB VỚI TTL VÀ GSI

#### 1. Tạo bảng `enterprise-cloud-devsecops-user-sessions`
1. Đăng nhập **AWS Management Console**, tìm kiếm dịch vụ **DynamoDB**.
2. Menu trái chọn **Tables** -> Bấm nút màu cam **Create table**.
3. Điền thông tin:
   - **Table name**: `enterprise-cloud-devsecops-user-sessions`
   - **Partition key**: `sessionId` (Kiểu dữ liệu: `String`)
   - **Table settings**: Chọn **Customize settings**
   - **Table class**: `DynamoDB Standard`
   - **Capacity mode**: Chọn **On-demand** (FinOps khuyến nghị: chỉ trả tiền theo request thực tế phát sinh)
   - **Encryption at rest**: Chọn `Owned by Amazon Web Services (Default)` (Miễn phí)
4. Bấm **Create table**.
5. **Cấu hình Global Secondary Index (GSI)**:
   - Trong chi tiết bảng `enterprise-cloud-devsecops-user-sessions`, chọn tab **Indexes** -> Bấm **Create index**.
   - **Partition key**: `userId` (Kiểu: `String`)
   - **Sort key**: `createdAt` (Kiểu: `Number`)
   - **Index name**: `userId-createdAt-index`
   - **Attribute projections**: Chọn `All` -> Bấm **Create index**.
6. **Kích hoạt Time-To-Live (TTL)**:
   - Chọn tab **Additional settings** trong bảng.
   - Tại mục *Time to Live (TTL)* -> Bấm nút **Turn on**.
   - **TTL attribute name**: Nhập chính xác `expiresAt`.
   - Bấm **Turn on TTL**.

#### 2. Tạo bảng `enterprise-cloud-devsecops-cart`
1. Tại màn hình **Tables** -> Bấm **Create table**.
2. Điền thông tin:
   - **Table name**: `enterprise-cloud-devsecops-cart`
   - **Partition key**: `userId` (Kiểu: `String`)
   - **Sort key**: `itemId` (Kiểu: `String`)
   - **Table settings**: Chọn **Customize settings** -> Chọn **On-demand**.
3. Bấm **Create table**.
4. **Kích hoạt Time-To-Live (TTL)**:
   - Vào tab **Additional settings** -> Bấm **Turn on TTL**.
   - **TTL attribute name**: `expiresAt` -> Bấm **Turn on TTL**.

---

### PHẦN B: CẤU HÌNH S3 LIFECYCLE CHUYỂN SANG S3 GLACIER (TIẾT KIỆM CHI PHÍ)

1. Mở dịch vụ **Amazon S3**, click chọn bucket `enterprise-cloud-devsecops-static-assets-<region>`.
2. Chuyển sang tab **Management**.
3. Tại mục *Lifecycle rules* -> Bấm nút **Create lifecycle rule**.
4. **Quy tắc 1: Lưu trữ tài liệu cũ sang Glacier**:
   - **Lifecycle rule name**: `archive-uploads-to-glacier-after-30-days`
   - **Choose a rule scope**: Chọn **Limit the scope of this rule using one or more filters**.
   - **Prefix**: Điền `uploads/`
   - **Lifecycle rule actions**: Tích chọn:
     * ☑ `Move current versions of objects between storage classes`
   - **Transition current versions of objects between storage classes**:
     * *Storage class transitions*: Chọn **Glacier Flexible Retrieval** (hoặc Glacier Instant Retrieval)
     * *Days after object creation*: Điền `30`
   - Bấm **Create rule**.
5. **Quy tắc 2: Tối ưu chi phí phiên bản cũ (Noncurrent Version Management)**:
   - Bấm **Create lifecycle rule** lần thứ 2.
   - **Lifecycle rule name**: `manage-noncurrent-versions`
   - **Choose a rule scope**: Chọn **Apply to all objects in the bucket** (☑ *I acknowledge...*).
   - **Lifecycle rule actions**: Tích chọn 2 mục:
     * ☑ `Move noncurrent versions of objects between storage classes`
     * ☑ `Permanently delete noncurrent versions of objects`
   - **Transitions**:
     * Chọn **Glacier Flexible Retrieval** sau `30` ngày kể từ khi trở thành noncurrent.
   - **Expiration**:
     * *Days after objects become noncurrent*: Điền `90` ngày để xóa vĩnh viễn phiên bản rác.
   - Bấm **Create rule**.

---

## 14. PHƯƠNG PHÁP 3: KIỂM THỬ TỰ ĐỘNG HÓA QUA AWS CLI & SCRIPTS

Thành viên 3 đã đóng gói kịch bản kiểm thử toàn diện giúp xác thực hạ tầng chỉ bằng 1 câu lệnh duy nhất:

### Chạy bằng PowerShell (Windows):
```powershell
cd finops/scripts

# Kiểm thử toàn diện (Kiểm tra trạng thái + CRUD Session & Cart + S3 Lifecycle)
.\test_dynamodb.ps1 -Action All

# Hoặc chỉ kiểm tra trạng thái bảng và TTL:
.\test_dynamodb.ps1 -Action Status

# Dọn dẹp các bản ghi test sau khi chụp ảnh:
.\test_dynamodb.ps1 -Action Cleanup
```

### Chạy bằng Bash (Linux / macOS / Git Bash):
```bash
cd finops/scripts
chmod +x test_dynamodb.sh

# Kiểm thử toàn diện
./test_dynamodb.sh ap-southeast-1 enterprise-cloud-devsecops all
```

---

## 15. NGUYÊN LÝ TỐI ƯU CHI PHÍ FINOPS TUẦN 3

### 1. Phân tích chi phí DynamoDB: On-Demand vs. Provisioned Free Tier
- **Mô hình On-Demand (`PAY_PER_REQUEST`)**:
  - Không tốn bất kỳ chi phí cố định nào khi không có người dùng truy cập.
  - Phù hợp tuyệt đối cho môi trường đồ án sinh viên, chạy demo vài giờ trong tuần.
  - Chi phí: $1.25 cho 1 triệu Write Request Units, $0.25 cho 1 triệu Read Request Units. Trong phạm vi đồ án, chi phí thực tế gần như **$0.00**.
- **Cơ chế Time-To-Live (TTL)**:
  - AWS tự động xóa các items có timestamp `expiresAt` nhỏ hơn thời gian hiện tại.
  - Quá trình quét và xóa dữ liệu hết hạn của TTL là **hoàn toàn miễn phí** (không tốn Write Capacity Units và không ảnh hưởng hiệu năng bảng).
  - Tránh phình dung lượng lưu trữ bảng theo thời gian.

### 2. Phân tích tối ưu lưu trữ S3 Glacier
| Tiêu chí | S3 Standard | S3 Glacier Flexible Retrieval | Mức độ tối ưu FinOps |
| :--- | :--- | :--- | :---: |
| **Đơn giá lưu trữ** | ~$0.025 / GB / tháng | ~$0.004 / GB / tháng | 📉 **Tiết kiệm 84% chi phí** |
| **Mục đích sử dụng** | Ảnh đại diện, avatar web truy cập thường xuyên | Hóa đơn giao dịch cũ, hồ sơ lưu trữ sau 30 ngày | Chuẩn vòng đời dữ liệu doanh nghiệp |
| **Cơ chế tự động** | Dữ liệu nạp ban đầu | Chuyển đổi tự động qua S3 Lifecycle Rule | 100% tự động không cần can thiệp tay |

---

## 16. DANH MỤC ẢNH MINH CHỨNG HOÀN THÀNH TUẦN 3 (DELIVERABLE CHECKLIST)

Khi nộp báo cáo tiến độ Tuần 3, Thành viên 3 chuẩn bị 4 bức ảnh minh chứng sau:

| STT | Tên ảnh minh chứng | Nội dung cần thể hiện trên ảnh | Tiêu chuẩn đánh giá |
| :---: | :--- | :--- | :---: |
| **01** | `dynamodb-tables-active.png` | Danh sách bảng DynamoDB trên Console: `user-sessions` và `cart` đều ở trạng thái `Active`, chế độ `On-Demand` | 🟢 Đạt chuẩn NoSQL |
| **02** | `dynamodb-ttl-and-gsi.png` | Chi tiết bảng `user-sessions` hiển thị TTL `expiresAt = Enabled` và GSI `userId-createdAt-index = Active` | 🟢 Đạt chuẩn FinOps & Indexing |
| **03** | `s3-lifecycle-glacier-rules.png` | Tab Management của S3 Bucket hiển thị 2 Lifecycle Rules chuyển `uploads/` sang `Glacier` sau 30 ngày | 🟢 Đạt chuẩn FinOps Storage |
| **04** | `dynamodb-crud-cli-test.png` | Terminal chạy script `test_dynamodb.ps1` trả về kết quả `[OK]` ghi đọc dữ liệu độ trễ thấp và hiển thị đầy đủ quy tắc S3 | 🟢 Đạt chuẩn Automation |

---

# HƯỚNG DẪN TRIỂN KHAI TUẦN 4: CLOUDWATCH METRICS, ALARMS, DASHBOARDS & AUDIT TRAIL CLOUDTRAIL

> **Phân mảng:** Thành viên 3 (Dữ liệu & FinOps — Phạm Thế Hùng)  
> **Mục tiêu Tuần 4:**  
> 1. Thiết lập hệ thống giám sát tập trung **Amazon CloudWatch**: Log Groups giới hạn lưu trữ 7 ngày (FinOps guardrail), Metric Alarms cảnh báo quá tải **CPU >= 70%** (cho RDS MySQL & Container) và hạn mức ngân sách qua SNS Email.  
> 2. Xây dựng **CloudWatch Observability Dashboard** trực quan hóa toàn bộ hạ tầng 3 tầng (Database RDS, Compute ECS, Network ALB/WAF Defense và Chi phí FinOps) theo thời gian thực phục vụ Màn 3 bảo vệ đồ án.  
> 3. Kích hoạt **AWS CloudTrail** ghi vết kiểm toán (Audit Trail) 100% các hành vi gọi API quản trị, lưu trữ vào S3 Bucket chuyên dụng kèm mã hóa SSE-S3 và vòng đời tự động chuyển sang **S3 Glacier** sau 30 ngày.

---

## 17. TỔNG QUAN DELIVERABLES TUẦN 4

Thành viên 3 bàn giao bộ giải pháp kỹ thuật hoàn chỉnh cho Tuần 4 bao gồm:

| Deliverable | Vị trí tệp | Mô tả kỹ thuật | Trạng thái |
| :--- | :--- | :--- | :---: |
| **CloudWatch IaC** | [`finops/terraform/cloudwatch.tf`](file:///c:/Users/Pham%20The%20Hung/ENTERPRISE-CLOUD-DEVSECOPS-PLATFORM/finops/terraform/cloudwatch.tf) | SNS Topic, 4 Log Groups (Retention 7 ngày), 5 Metric Alarms (CPU > 70%, Low Storage, Low RAM, Billing), Observability Dashboard đa tầng | ✅ |
| **CloudTrail IaC** | [`finops/terraform/cloudtrail.tf`](file:///c:/Users/Pham%20The%20Hung/ENTERPRISE-CLOUD-DEVSECOPS-PLATFORM/finops/terraform/cloudtrail.tf) | Dedicated S3 Bucket, Block Public Access 100%, SSE-S3, S3 Glacier Lifecycle, IAM Role chuyển log sang CloudWatch Logs, CloudTrail Trail | ✅ |
| **Variables & Outputs** | [`finops/terraform/variables.tf`](file:///c:/Users/Pham%20The%20Hung/ENTERPRISE-CLOUD-DEVSECOPS-PLATFORM/finops/terraform/variables.tf), [`outputs.tf`](file:///c:/Users/Pham%20The%20Hung/ENTERPRISE-CLOUD-DEVSECOPS-PLATFORM/finops/terraform/outputs.tf) | Cấu hình tham số ngưỡng cảnh báo, log retention và xuất Dashboard URL, Alarm ARNs, Trail Name bàn giao nhóm | ✅ |
| **Test Scripts CLI** | [`finops/scripts/test_observability.ps1`](file:///c:/Users/Pham%20The%20Hung/ENTERPRISE-CLOUD-DEVSECOPS-PLATFORM/finops/scripts/test_observability.ps1), [`test_observability.sh`](file:///c:/Users/Pham%20The%20Hung/ENTERPRISE-CLOUD-DEVSECOPS-PLATFORM/finops/scripts/test_observability.sh) | Script kiểm thử toàn diện trạng thái Dashboard, Alarms, Logs, CloudTrail và hỗ trợ **mô phỏng kích hoạt chuông báo động (Trigger Alarm)** để bắn email tức thì khi live demo | ✅ |

---

## 18. PHƯƠNG PHÁP 1: TRIỂN KHAI QUA TERRAFORM (ENTERPRISE STANDARD)

### Bước 1: Kiểm tra cú pháp và kế hoạch triển khai
```bash
cd finops/terraform

# Kiểm tra cú pháp HCL
terraform validate

# Xem trước kế hoạch (~15 tài nguyên mới được khởi tạo)
terraform plan
```

### Bước 2: Triển khai lên AWS
```bash
terraform apply -auto-approve
```

### Bước 3: Xem kết quả bàn giao
```bash
# Xem Dashboard URL
terraform output cloudwatch_dashboard_url

# Xem thông số Alarms và CloudTrail
terraform output cloudwatch_rds_cpu_alarm_name
terraform output cloudtrail_trail_name
terraform output cloudtrail_s3_bucket_name
```

---

## 19. PHƯƠNG PHÁP 2: THỰC HIỆN TRÊN AWS MANAGEMENT CONSOLE (ĐỂ CHỤP ẢNH MINH CHỨNG)

### PHẦN A: THIẾT LẬP CLOUDWATCH LOG GROUPS & RETENTION (FINOPS GUARDRAIL)
1. Đăng nhập [AWS Management Console](https://console.aws.amazon.com/), tìm dịch vụ **CloudWatch**.
2. Menu trái chọn **Logs** -> **Log groups**.
3. Bấm **Create log group** để tạo lần lượt:
   - `/ecs/enterprise-cloud-devsecops-backend-app`
   - `/aws/rds/instance/enterprise-cloud-devsecops-mysql-primary/error`
   - `/aws/rds/instance/enterprise-cloud-devsecops-mysql-primary/slowquery`
   - `/aws/cloudtrail/enterprise-cloud-devsecops-audit-logs`
4. **Cấu hình Retention (BẮT BUỘC ĐỂ TIẾT KIỆM CREDIT)**:
   - Trong danh sách Log groups, tích chọn từng Log group vừa tạo.
   - Chọn menu **Actions** -> **Edit retention setting**.
   - Chọn `7 days` (1 week) thay vì `Never expire` -> Bấm **Save**.

---

### PHẦN B: CẤU HÌNH SNS TOPIC & METRIC ALARMS (CPU > 70%)
1. **Tạo SNS Topic nhận cảnh báo**:
   - Vào dịch vụ **Amazon SNS** -> **Topics** -> Bấm **Create topic**.
   - Chọn kiểu **Standard**, đặt tên `enterprise-cloud-devsecops-alerts-topic` -> Bấm **Create topic**.
   - Bấm **Create subscription** -> Protocol chọn `Email` -> Endpoint nhập email các thành viên nhóm -> Bấm **Create subscription**.
   - *Lưu ý:* Mở email cá nhân bấm link **Confirm subscription**.
2. **Tạo Alarm cảnh báo RDS CPU > 70%**:
   - Quay lại dịch vụ **CloudWatch** -> Menu trái chọn **Alarms** -> **All alarms** -> Bấm **Create alarm**.
   - Bấm **Select metric** -> Chọn `RDS` -> `Per-Database Metrics` -> Tích chọn `CPUUtilization` của DB instance `enterprise-cloud-devsecops-mysql-primary`.
   - **Conditions**:
     * *Threshold type*: `Static`
     * *Whenever CPUUtilization is...*: `Greater than or equal to (>=)`
     * *Than...*: `70`
     * *Additional configuration*: Datapoints to alarm: `2 out of 2` (chu kỳ 5 phút).
   - **Notification**:
     * *Alarm state trigger*: Chọn `In alarm`.
     * *Send a notification to...*: Chọn SNS topic `enterprise-cloud-devsecops-alerts-topic`.
   - Đặt tên Alarm: `enterprise-cloud-devsecops-rds-cpu-high-alert` -> Bấm **Create alarm**.
3. **Tạo Alarm cảnh báo Container/Compute CPU > 70%**:
   - Tạo tương tự với metric `AWS/ECS` `CPUUtilization` hoặc `AWS/EC2` `CPUUtilization`, ngưỡng `>= 70%`, đặt tên `enterprise-cloud-devsecops-compute-cpu-high-alert`.

---

### PHẦN C: KHỞI TẠO CLOUDWATCH OBSERVABILITY DASHBOARD
1. Trong dịch vụ **CloudWatch**, menu trái chọn **Dashboards** -> Bấm nút màu cam **Create dashboard**.
2. Đặt tên: `enterprise-cloud-devsecops-observability-dashboard` -> Bấm **Create dashboard**.
3. Thêm các widget quan sát cốt lõi:
   - **Widget 1: RDS CPU (%)**: Chọn Line chart -> Metric `AWS/RDS` -> `CPUUtilization` -> Đặt ngưỡng ngang 70% màu đỏ.
   - **Widget 2: RDS Connections**: Metric `DatabaseConnections`.
   - **Widget 3: RDS Storage**: Metric `FreeStorageSpace`.
   - **Widget 4: Compute CPU**: Metric `AWS/ECS` hoặc `EC2` -> `CPUUtilization`.
   - **Widget 5: Network ALB & WAF Defense**: Metric `AWS/ApplicationELB` `RequestCount` và `AWS/WAFV2` `BlockedRequests` (trình diễn Màn 2).
   - **Widget 6: FinOps Billing**: Metric `AWS/Billing` -> `EstimatedCharges` (khu vực us-east-1).
   - **Widget 7: Alarms Status**: Thêm widget kiểu `Alarm status` chọn danh sách các Alarms vừa tạo.
4. Bấm **Save dashboard**.

---

### PHẦN D: KÍCH HOẠT AWS CLOUDTRAIL GHI VẾT KIỂM TOÁN VÀO S3
1. **Tạo S3 Bucket lưu vết**:
   - Vào dịch vụ **Amazon S3** -> Bấm **Create bucket**.
   - Tên bucket: `enterprise-cloud-devsecops-cloudtrail-audit-<account-id>-ap-southeast-1`.
   - Giữ nguyên tích chọn **Block all public access** (bảo mật tuyệt đối).
   - Encryption: Chọn `SSE-S3`.
   - Tab **Management**: Tạo Lifecycle rule `archive-to-glacier` chuyển prefix `AWSLogs/` sang `Glacier` sau `30` ngày và expire sau `90` ngày.
2. **Kích hoạt CloudTrail Trail**:
   - Vào dịch vụ **CloudTrail** -> Menu trái chọn **Trails** -> Bấm **Create trail**.
   - **Trail name**: `enterprise-cloud-devsecops-audit-trail`.
   - **Storage location**: Chọn **Use existing S3 bucket** -> Chọn bucket vừa tạo ở trên.
   - **Log file validation**: Tích chọn `Enabled` (đảm bảo tính toàn vẹn).
   - **CloudWatch Logs**: Tích chọn `Enabled` -> Chọn Log Group `/aws/cloudtrail/enterprise-cloud-devsecops-audit-logs`.
   - **Event type**: Chọn **Management events** (Read & Write events). Bỏ qua Data events (FinOps guardrail tránh tốn tiền đọc ghi S3).
   - Bấm **Create trail**.

---

## 20. PHƯƠNG PHÁP 3: KIỂM THỬ TỰ ĐỘNG HÓA & MÔ PHỎNG CHUÔNG BÁO ĐỘNG (DEMO MÀN 3)

Thành viên 3 đã đóng gói kịch bản kiểm thử và mô phỏng sự cố bằng 1 dòng lệnh:

### Chạy bằng PowerShell (Windows):
```powershell
cd finops/scripts

# 1. Kiểm tra trạng thái toàn diện (Dashboard, Logs, Alarms, CloudTrail)
.\test_observability.ps1 -Action Status

# 2. [LIVE DEMO MÀN 3] Mô phỏng sự cố CPU 85% quá tải để SNS bắn Email tự động tức thì!
.\test_observability.ps1 -Action TriggerAlarm

# 3. Trả lại trạng thái bình thường (OK) sau khi giảng viên chấm xong
.\test_observability.ps1 -Action ResetAlarm

# 4. Xem 5 sự kiện gọi API gần nhất được CloudTrail ghi vết
.\test_observability.ps1 -Action TailLogs
```

### Chạy bằng Bash (Linux / macOS / Git Bash):
```bash
cd finops/scripts
chmod +x test_observability.sh

# Kiểm tra toàn diện
./test_observability.sh ap-southeast-1 enterprise-cloud-devsecops all

# Kích hoạt báo động email demo
./test_observability.sh ap-southeast-1 enterprise-cloud-devsecops trigger

# Trả lại trạng thái OK
./test_observability.sh ap-southeast-1 enterprise-cloud-devsecops reset
```

---

## 21. NGUYÊN LÝ TỐI ƯU CHI PHÍ FINOPS TUẦN 4

### 1. Phân tích chi phí CloudWatch Logs: 7 Days Retention vs. Never Expire
- **Vấn đề thực tế**: Mặc định AWS CloudWatch Log Groups được tạo với thuộc tính `Never expire`. Trong hệ thống doanh nghiệp hoặc môi trường đồ án sinh viên, các log ứng dụng và truy vấn CSDL sẽ phình lên hàng gigabyte sau vài tuần, gây phát sinh chi phí lưu trữ log ngầm ($0.03 / GB / tháng).
- **Giải pháp FinOps của Member 3**: Cưỡng chế đặt `retention_in_days = 7` cho 100% Log Groups. Sau 7 ngày, log cũ được tự động thu hồi và tiêu hủy miễn phí, đảm bảo chi phí lưu trữ log luôn tiệm cận **$0.00**.

### 2. AWS CloudTrail Free Tier Management Events vs. Paid Data Events
- **Cơ chế AWS CloudTrail**: Bản sao đầu tiên của **Management Events** (các lệnh gọi API như tạo máy chủ, đổi IAM, sửa RDS) là **HOÀN TOÀN MIỄN PHÍ**.
- **Giải pháp FinOps của Member 3**: Chỉ bật Management Events, **TUYỆT ĐỐI KHÔNG BẬT S3 Data Events** (vì S3 Data Events tính phí $0.10 cho mỗi 100,000 sự kiện đọc/ghi). Điều này giúp ghi lại 100% nhật ký quản trị mà không tốn thêm 1 cent nào.

### 3. Tối ưu chi phí S3 Glacier cho Audit Logs dài hạn
- Các tệp nén kiểm toán `.json.gz` đẩy từ CloudTrail sang S3 được cấu hình S3 Lifecycle tự động chuyển sang **S3 Glacier Flexible Retrieval** sau 30 ngày (tiết kiệm 84% đơn giá lưu trữ) và xóa sau 90 ngày.

---

## 22. DANH MỤC ẢNH MINH CHỨNG HOÀN THÀNH TUẦN 4 (DELIVERABLE CHECKLIST)

Khi nộp báo cáo tiến độ Tuần 4, Thành viên 3 chuẩn bị 4 bức ảnh minh chứng sau:

| STT | Tên ảnh minh chứng | Nội dung cần thể hiện trên ảnh | Tiêu chuẩn đánh giá |
| :---: | :--- | :--- | :---: |
| **01** | `cloudwatch-observability-dashboard.png` | CloudWatch Dashboard hiển thị đầy đủ các widget: RDS MySQL CPU/Connections/Storage, Compute CPU, WAF Blocked Requests và FinOps Estimated Charges | 🟢 Đạt chuẩn Enterprise Observability |
| **02** | `cloudwatch-alarms-configured.png` | Danh sách CloudWatch Alarms: `rds-cpu-high-alert` (ngưỡng 70%), `compute-cpu-high-alert` (70%), `free-storage-low-alert` ở trạng thái `OK` hoặc `In alarm` | 🟢 Đạt chuẩn High Availability |
| **03** | `cloudtrail-trail-logging.png` | CloudTrail Console hiển thị Trail `enterprise-cloud-devsecops-audit-trail` có trạng thái `Logging = Yes`, gắn đúng S3 Bucket và CloudWatch Log Group | 🟢 Đạt chuẩn Audit Compliance |
| **04** | `cloudwatch-alarm-email-received.png` | Hộp thư email nhận được thư cảnh báo tức thì từ AWS SNS với tiêu đề `ALARM: "enterprise-cloud-devsecops-rds-cpu-high-alert"` | 🟢 Đạt chuẩn Incident Notification |

---

# HƯỚNG DẪN TRIỂN KHAI PHÂN TÍCH DỮ LIỆU & FINOPS — TUẦN 5

> **Phân mảng:** Thành viên 3 (Dữ liệu & FinOps — Phạm Thế Hùng)  
> **Mục tiêu Tuần 5:** Khởi chạy Amazon Redshift Serverless demo 1–2 giờ, nạp dữ liệu mẫu e-commerce chạy 7 câu truy vấn phân tích (Business Intelligence), chụp ảnh minh chứng rồi xóa sạch hoàn toàn để bảo toàn ngân sách $200 USD.

---

## 23. TỔNG QUAN KIẾN TRÚC AMAZON REDSHIFT SERVERLESS TUẦN 5

Amazon Redshift Serverless cho phép chạy kho dữ liệu phân tích cấp doanh nghiệp (Data Warehouse) mà không cần cấp phát cụm máy chủ phần cứng cố định.

```
┌────────────────────────────────────────────────────────────────────────┐
│             KIẾN TRÚC KHO DỮ LIỆU EPHEMERAL REDSHIFT SERVERLESS        │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  [Dữ liệu giao dịch]          [Dữ liệu mẫu E-commerce]                │
│   RDS MySQL & DynamoDB              SQL Scripts                        │
│          │                               │                             │
│          └───────────────┬───────────────┘                             │
│                          ▼                                             │
│       ┌──────────────────────────────────────┐                         │
│       │ Amazon Redshift Serverless Namespace │                         │
│       │ • Database: analytics_db             │                         │
│       │ • Star Schema: Facts & Dimensions    │                         │
│       │ • Encryption: AWS KMS SSE            │                         │
│       └──────────────────┬───────────────────┘                         │
│                          │                                             │
│                          ▼                                             │
│       ┌──────────────────────────────────────┐                         │
│       │ Redshift Serverless Workgroup (8 RPU)│                         │
│       │ • Base Capacity: 8 RPU (Tối thiểu)   │                         │
│       │ • Đơn giá: $0.375 / RPU-giờ (~$3/giờ)│                         │
│       │ • Auto-pause khi không có truy vấn   │                         │
│       └──────────────────┬───────────────────┘                         │
│                          │                                             │
│       ┌──────────────────┴───────────────────┐                         │
│       ▼                                      ▼                         │
│ [Query Editor v2 / CLI]             [DỌN DẸP HOÀN TOÀN]                │
│  7 Business Analytics               Xóa sạch sau 1-2h demo             │
│  Doanh thu, Top SKUs, RFM           Chi phí: ~$4.50 USD (Tiết kiệm 99%)│
└────────────────────────────────────────────────────────────────────────┘
```

---

## 24. KỊCH BẢN VẬN HÀNH TỰ ĐỘNG HÓA VÒNG ĐỜI (LIFECYCLE DEMO)

Thành viên 3 đã cung cấp kịch bản tự động hóa 100% vòng đời Redshift Serverless bằng PowerShell và Bash:

### Sử dụng PowerShell (Windows):
```powershell
cd finops/scripts

# 1. Bật cờ enable_redshift_demo và tạo cụm Redshift Serverless (8 RPU)
.\demo_redshift.ps1 -Action Deploy

# 2. Xem thông tin Endpoint & kết nối
.\demo_redshift.ps1 -Action Status

# 3. Nạp Star Schema (Dim_Customers, Dim_Products, Dim_Date, Fact_Sales, Fact_Payments)
.\demo_redshift.ps1 -Action LoadData

# 4. Thực thi 7 câu truy vấn phân tích kinh doanh và xuất bảng kết quả
.\demo_redshift.ps1 -Action RunAnalytics

# 5. [BẮT BUỘC SAU KHI DEMO] Tiêu hủy cụm Redshift để bảo vệ credit $200!
.\demo_redshift.ps1 -Action Destroy
```

### Sử dụng Bash (Linux / macOS / Git Bash):
```bash
cd finops/scripts
chmod +x demo_redshift.sh

# Triển khai cụm demo
./demo_redshift.sh deploy ap-southeast-1

# Nạp dữ liệu & Chạy truy vấn
./demo_redshift.sh load-data ap-southeast-1
./demo_redshift.sh run-analytics ap-southeast-1

# Dọn dẹp hoàn toàn
./demo_redshift.sh destroy ap-southeast-1
```

---

## 25. BỘ 7 TRUY VẤN PHÂN TÍCH KINH DOANH (7 BUSINESS ANALYTICS QUERIES)

Tệp SQL hoàn chỉnh nằm tại [`finops/scripts/configs/redshift_analytics_queries.sql`](file:///c:/Users/Pham%20The%20Hung/ENTERPRISE-CLOUD-DEVSECOPS-PLATFORM/finops/scripts/configs/redshift_analytics_queries.sql):

1. **Query 1: Doanh thu & Lợi nhuận tổng quan theo Quý/Tháng**: Đánh giá tổng doanh thu, giá vốn và biên lợi nhuận ròng.
2. **Query 2: Top 5 Sản phẩm bán chạy & Tỷ trọng đóng góp**: Tìm sản phẩm chủ lực mang lại biên lợi nhuận cao nhất.
3. **Query 3: Phân khúc khách hàng RFM (VIP, Gold, Silver, Standard)**: Đo lường Customer Lifetime Value (CLV).
4. **Query 4: Phân tích doanh số theo vùng địa lý**: Xếp hạng doanh thu theo thành phố và miền địa lý.
5. **Query 5: Cơ cấu phương thức thanh toán**: Tỷ trọng VNPay, MoMo, Thẻ tín dụng, COD và tỷ lệ thành công.
6. **Query 6: Quy mô đơn hàng trung bình (AOV - Average Order Value)**: Phân tích hành vi mua sắm cuối tuần vs ngày thường.
7. **Query 7: Giờ vàng giao dịch (Peak Hours)**: Khám phá khung giờ phát sinh giao dịch cao nhất trong ngày.

---

## 26. BÁO CÁO FINOPS & MINH CHỨNG HOÀN THÀNH TUẦN 5

- 📄 **Báo cáo tối ưu chi phí & dọn dẹp Redshift**: Xem tài liệu chi tiết tại [`finops/redshift-cost-optimization-report.md`](file:///c:/Users/Pham%20The%20Hung/ENTERPRISE-CLOUD-DEVSECOPS-PLATFORM/finops/redshift-cost-optimization-report.md).
- 💰 **Chi phí thực tế tiêu hao:** `$4.50 USD` (1.5 giờ demo với 8 RPU).
- 🛡️ **Tỷ lệ tiết kiệm FinOps:** `99.79%` so với cụm duy trì liên tục ($2,160 USD/tháng).
- 📸 **Danh mục ảnh minh chứng nộp báo cáo Tuần 5:**
  1. `redshift-query-editor-results.png`: Ảnh chụp màn hình kết quả chạy câu truy vấn BI trên AWS Redshift Query Editor v2.
  2. `redshift-cluster-cleanup-confirmed.png`: Ảnh chụp AWS Redshift Console xác nhận danh sách Workgroups & Namespaces đều ở trạng thái rỗng (0 cụm đang chạy).

