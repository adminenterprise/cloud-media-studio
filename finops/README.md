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

### Bước 1: Lấy thông số từ Member 1

Trước tiên cần lấy giá trị VPC và Subnet Group từ module mạng của Member 1:
```bash
cd terraform/
terraform output vpc_id
terraform output rds_db_subnet_group_name
```

### Bước 2: Cập nhật terraform.tfvars

Mở tệp `finops/terraform/terraform.tfvars` và điền giá trị thực:
```hcl
# Thay thế bằng giá trị thực từ Member 1
vpc_id                   = "vpc-0abc123def456"   # Từ bước 1
rds_db_subnet_group_name = "enterprise-cloud-devsecops-db-subnet-group"

# Đặt mật khẩu mạnh cho RDS admin
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

## 9. NẠP DỮ LIỆU KHỞI TẠO (INIT.SQL) TỪ MEMBER 2

Sau khi RDS ở trạng thái `Available`, kết nối và nạp schema từ file [`db/init.sql`](file:///c:/Users/Pham%20The%20Hung/ENTERPRISE-CLOUD-DEVSECOPS-PLATFORM/db/init.sql) của Member 2:

```bash
# Lấy endpoint RDS
RDS_ENDPOINT=$(cd finops/terraform && terraform output -raw rds_address)

# Kết nối và nạp schema (cần MySQL client)
mysql -h $RDS_ENDPOINT -u admin -p enterprise_db < db/init.sql
```

---

## 10. DANH MỤC ẢNH MINH CHỨNG TUẦN 2 (DELIVERABLE CHECKLIST)

| STT | Tên ảnh minh chứng | Nội dung cần thể hiện trên ảnh | Đánh giá đạt chuẩn |
| :---: | :--- | :--- | :---: |
| **01** | `rds-mysql-available.png` | RDS Console: Instance `Available`, db.t3.micro, Private subnet, Encrypted | 🟢 Đạt chuẩn Enterprise |
| **02** | `rds-security-group-rules.png` | Security Group: Inbound chỉ port 3306 từ App Subnets (10.0.10.0/24, 10.0.11.0/24) | 🟢 Đạt chuẩn Least Privilege |
| **03** | `s3-bucket-sse-s3-enabled.png` | S3 Console: Default encryption = SSE-S3 (AES256) | 🟢 Đạt chuẩn Encryption |
| **04** | `s3-block-public-access.png` | S3 Console: Block all public access = ON (4/4 tích) | 🟢 Đạt chuẩn Security |
