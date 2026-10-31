# CẨM NANG DIỄN TẬP LIVE DEMO — TUẦN 6
## DỰ ÁN: ENTERPRISE CLOUD & DEVSECOPS PLATFORM

> **Mục tiêu**: Chuẩn hóa quy trình trình diễn trực tiếp (Live Demo) 3 kịch bản cốt lõi trước Hội đồng chấm thi, phân công rõ vai trò 4 thành viên, chuẩn bị sẵn sàng các câu lệnh và phương án dự phòng.  
> **Thời lượng diễn tập dự kiến**: 15 – 20 phút.

---

## 1. TỔNG QUAN PHÂN VAI & THỨ TỰ TRÌNH DIỄN

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       TIẾN TRÌNH DIỄN TẬP DEMO (15 PHÚT)                    │
├───────────────────┬───────────────────┬───────────────────┬─────────────────┤
│ Mở đầu (2 phút)   │ Màn 1 (5 phút)    │ Màn 2 (5 phút)    │ Màn 3 (5 phút)  │
│ Giới thiệu chung  │ Self-Healing Demo │ WAF Defense Demo  │ FinOps & IaC    │
│ & Kiến trúc mạng  │ Tự phục hồi máy   │ Chặn đứng SQLi    │ Kiểm soát $200  │
│ (Member 1 - Lead) │ (Member 2 - Host) │ (Member 4 - Host) │ (Member 3 - Host│
│                   │ (Member 1 Support)│ (Member 1 Support)│  & Member 1)    │
└───────────────────┴───────────────────┴───────────────────┴─────────────────┘
```

---

## 2. CHECKLIST CHUẨN BỊ TRƯỚC GIỜ G (PRE-DEMO CHECKLIST)

Trước khi bắt đầu buổi diễn tập hoặc thi chính thức, 4 thành viên kiểm tra các hạng mục sau:

- [ ] **Hạ tầng Mạng (Member 1)**: Đã chạy `deploy.ps1` hoặc `deploy.sh`. Trạng thái ALB là `Active`, WAF Web ACL đã gắn vào ALB.
- [ ] **Tầng Compute (Member 2)**: Container ECS Fargate / EC2 Instance đang `InService` và `Healthy` trong ALB Target Group.
- [ ] **Tầng Dữ liệu & FinOps (Member 3)**: RDS MySQL đang chạy, AWS Budgets và Cost Explorer đã có số liệu chi tiêu hiển thị.
- [ ] **Tầng DevSecOps (Member 4)**: Đã chuẩn bị sẵn terminal với công cụ `curl`, Postman hoặc trình duyệt web; đã mở sẵn tab **CloudWatch WAF Metrics**.
- [ ] **Dự phòng (Toàn nhóm)**: Đã chuẩn bị sẵn video quay màn hình chạy trước (đề phòng mạng hội trường yếu hoặc sự cố đột xuất).

---

## 3. KỊCH BẢN CHI TIẾT 3 MÀN DEMO

---

### PHẦN MỞ ĐẦU (0:00 - 2:00): GIỚI THIỆU TỔNG QUAN & KIẾN TRÚC MẠNG
- **Người trình bày**: **Thành viên 1 (Nhóm trưởng)**
- **Màn hình hiển thị**: Sơ đồ kiến trúc Multi-VPC trong `terraform/README.md`.
- **Nội dung thuyết minh**:
  > *"Kính thưa Thầy/Cô Hội đồng, hệ thống Enterprise Cloud & DevSecOps Platform của nhóm chúng em được xây dựng 100% Cloud-Native theo kiến trúc 3-Tier Multi-AZ, tự động hóa hạ tầng hoàn toàn bằng Terraform. Toàn bộ hệ thống áp dụng mô hình Dual-VPC: Production VPC độc lập cho ứng dụng và Management VPC kết nối qua VPC Peering. Sau đây, nhóm xin phép trình diễn 3 kịch bản thực nghiệm cốt lõi chứng minh tính sẵn sàng cao (High Availability), năng lực phòng thủ an ninh mạng (DevSecOps) và quản trị tối ưu tài chính (FinOps)."*

---

### MÀN 1 (2:00 - 7:00): SELF-HEALING — TỰ ĐỘNG PHỤC HỒI HẠ TẦNG KHI CÓ SỰ CỐ
- **Người chủ trì**: **Thành viên 2 (Tính toán & Container)**
- **Hỗ trợ hạ tầng**: **Thành viên 1** (giải thích luồng ALB và Target Group Health Check)
- **Mục tiêu**: Chứng minh hệ thống tự phát hiện máy chủ/task chết và tự tạo mới thay thế mà không làm gián đoạn người dùng (Zero Downtime).

#### Các bước thực hiện:
1. **Bước 1 — Kiểm tra trạng thái bình thường**:
   - Mở trình duyệt truy cập vào tên miền ALB (`alb_dns_name`) hoặc CloudFront.
   - Trang web hiển thị bình thường, giao diện mượt mà (HTTP 200 OK).
2. **Bước 2 — Cưỡng bức tạo sự cố (Simulate Failure)**:
   - Thành viên 2 mở AWS Console -> Amazon ECS (hoặc EC2 Auto Scaling Group).
   - Chọn 1 task container đang chạy và ấn **Stop** (hoặc chọn 1 máy ảo EC2 và ấn **Terminate**).
   - Chỉ cho Hội đồng thấy số lượng task/instance giảm từ 2 xuống 1.
3. **Bước 3 — Trình diễn tính liên tục của dịch vụ**:
   - Quay lại trình duyệt, liên tục ấn **F5 (Reload)**.
   - Trang web **vẫn hoạt động 100% không hề bị lỗi**, do Application Load Balancer lập tức phát hiện và chuyển tiếp 100% lưu lượng sang node còn sống ở Availability Zone còn lại.
4. **Bước 4 — Chứng minh năng lực Tự phục hồi (Self-Healing)**:
   - Quay lại AWS Console sau 60–90 giây.
   - Auto Scaling Group / ECS Service tự động sinh ra một Task/Instance mới thay thế để duy trì Desired Count = 2.
   - Target Group chuyển sang trạng thái `healthy` trở lại.

---

### MÀN 2 (7:00 - 12:00): WAF DEFENSE — PHÒNG THỦ AN NINH MẠNG TRỰC CHIẾN
- **Người chủ trì**: **Thành viên 4 (Bảo mật & DevSecOps)**
- **Hỗ trợ hạ tầng**: **Thành viên 1** (WAF Web ACL rules) & **Thành viên 3** (CloudWatch log dashboard)
- **Mục tiêu**: Bắn các payload tấn công thực tế và chứng minh AWS WAF chặn đứng ngay tại rìa trước khi chạm tới ứng dụng.

#### Kịch bản & Bộ lệnh thực thi:

##### Thử nghiệm 1: Tấn công SQL Injection (SQLi)
- **Lệnh thực thi trên Terminal**:
  ```bash
  # Lấy DNS ALB từ output của Member 1
  ALB_URL="http://<alb-dns-name>"

  # Gửi request bình thường (Kết quả mong muốn: HTTP 200)
  curl -i "${ALB_URL}/api/users?name=john"

  # Gửi payload SQL Injection tấn công (Kết quả mong muốn: HTTP 403 Forbidden)
  curl -i "${ALB_URL}/api/users?name=' OR 1=1 --"
  ```
- **Thực tế diễn ra**:
  - Request chứa payload `' OR 1=1 --` bị AWS WAF nhận diện thông qua bộ luật `AWSManagedRulesSQLiRuleSet` và lập tức trả về:
  ```http
  HTTP/1.1 403 Forbidden
  Server: awselb/2.0
  Content-Type: text/html
  Content-Length: 134
  ```

##### Thử nghiệm 2: Tấn công Cross-Site Scripting (XSS)
- **Lệnh thực thi**:
  ```bash
  curl -i "${ALB_URL}/api/comment?content=<script>alert('HACKED')</script>"
  ```
- **Thực tế diễn ra**: Trả về `403 Forbidden` do vi phạm bộ luật `AWSManagedRulesCommonRuleSet`.

##### Thử nghiệm 3: Tấn công từ chối dịch vụ (Rate Limiting)
- **Lệnh thực thi**: Gửi nhanh trên 100 requests liên tục trong vòng vài giây:
  ```bash
  # Chạy vòng lặp bắn 120 requests
  for i in {1..120}; do curl -s -o /dev/null -w "%{http_code}\n" "${ALB_URL}/"; done
  ```
- **Thực tế diễn ra**: Sau ngưỡng 100 requests, các requests tiếp theo lập tức bị chặn với mã `403`.

##### Thuyết minh trên CloudWatch:
- Thành viên 4 chuyển tab sang **AWS CloudWatch / WAF Metrics**:
- Chỉ cho Hội đồng thấy đồ thị đường dốc:
  - Metric `BlockedRequests` tăng vọt.
  - Phân tích chi tiết rule nào đã kích hoạt (`AWSManagedRulesSQLiRuleSet` và `Custom-RateLimit`).

---

### MÀN 3 (12:00 - 17:00): FINOPS & TỰ ĐỘNG HÓA HẠ TẦNG (IaC)
- **Người chủ trì**: **Thành viên 3 (Dữ liệu & FinOps)** & **Thành viên 1 (Mạng & IaC)**
- **Mục tiêu**: Thể hiện tư duy quản trị tài chính doanh nghiệp, kiểm soát gói tài trợ $200 và năng lực tự động hóa hạ tầng bằng mã nguồn.

#### Nội dung thuyết trình:
1. **Trình diễn IaC 1-Click (Thành viên 1)**:
   - Trình chiếu cây thư mục Terraform: Phân chia module rõ ràng, không hardcode credentials, các tham số cấu hình tách biệt trong `variables.tf`.
   - Trình diễn script `deploy.ps1` / `deploy.sh`: Tự động kiểm tra cú pháp, format, validate và apply chuẩn xác.
   - Thao tác xuất `terraform output` bàn giao tham số rõ ràng cho các thành viên.
2. **Trình diễn FinOps & AWS Well-Architected Tool (Thành viên 3)**:
   - Mở **AWS Budgets**: Trình chiếu chính sách cảnh báo theo 2 mốc $20 và $50, minh chứng email nhận thông báo cảnh báo tự động.
   - Mở **AWS Cost Explorer**: Phân tích biểu đồ tiêu thụ thực tế của cả nhóm (dao động từ $45 – $65), chỉ ra các biện pháp tiết kiệm:
     - Dùng 1 NAT Gateway duy nhất cho Dev/Test (`enable_nat_gateway = false` khi không dùng).
     - Sử dụng ECS Fargate và RDS db.t3.micro tiết kiệm.
     - Thiết lập S3 Lifecycle chuyển tài liệu sang Glacier sau 30 ngày.
   - Mở **AWS Well-Architected Tool**: Báo cáo đánh giá hệ sinh thái theo 6 trụ cột:
     1. Operational Excellence (Vận hành xuất sắc qua IaC).
     2. Security (An ninh đa tầng với WAF & VPC cô lập).
     3. Reliability (Tính tin cậy với Multi-AZ & Self-Healing).
     4. Performance Efficiency (Hiệu năng với CloudFront CDN).
     5. Cost Optimization (Tối ưu chi phí FinOps $200).
     6. Sustainability (Tính bền vững, xóa tài nguyên không dùng).

---

## 4. PHƯƠNG ÁN DỰ PHÒNG KHI GẶP SỰ CỐ (CONTINGENCY PLAN)

| Rủi ro kỹ thuật | Giải pháp xử lý ngay lập tức |
| :--- | :--- |
| **Mạng Internet hội trường yếu / lag** | Chuyển ngay sang phát video đã quay sẵn tại nhà, thành viên thuyết minh live đè lên video. |
| **Lệnh `curl` bị timeout** | Kiểm tra Security Group của ALB xem có mở cổng 80 cho `0.0.0.0/0` không. |
| **ALB trả về 503 thay vì 200 khi test WAF** | Thành viên 1 giải thích rõ: ALB đang ở chế độ Fixed-Response hoặc Container đang khởi động; WAF vẫn chặn `403` chuẩn xác trước khi tới ALB. |
| **Hết credit AWS trong lúc demo** | Chuẩn bị sẵn bộ ảnh chụp màn hình đầy đủ các màn hình AWS Console, CloudWatch, Cost Explorer trong Slide. |

---

## 5. THU HỒI TÀI NGUYÊN SAU KHI KẾT THÚC BUỔI DEMO

Sau khi kết thúc diễn tập hoặc bảo vệ xong trước hội đồng, Thành viên 1 chạy lệnh thu hồi để bảo toàn tài khoản:

```powershell
# Trên Windows
cd terraform
.\scripts\destroy.ps1

# Trên Linux/macOS
cd terraform
./scripts/destroy.sh
```

