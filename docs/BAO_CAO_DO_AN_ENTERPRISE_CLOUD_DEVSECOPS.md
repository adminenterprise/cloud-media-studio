# BÁO CÁO ĐỒ ÁN MÔN HỌC: ĐIỆN TOÁN ĐÁM MÂY (CLOUD COMPUTING)
# ĐỀ TÀI: XÂY DỰNG NỀN TẢNG DOANH NGHIỆP ĐA TẦNG VÀ TỰ ĐỘNG HÓA VẬN HÀNH AN TOÀN TRÊN AWS (ENTERPRISE CLOUD & DEVSECOPS PLATFORM)

---

## THÔNG TIN CHUNG
- **Đơn vị đào tạo**: Khoa Công nghệ Thông tin
- **Bộ môn**: Mạng máy tính & Hệ thống truyền thông
- **Học phần**: Điện toán đám mây & Thực hành Điện toán đám mây
- **Quy mô đề tài**: Đồ án nhóm 4 thành viên (Chu kỳ triển khai: 7 tuần)
- **Giảng viên hướng dẫn**: [Điền tên Giảng viên]
- **Nhóm sinh viên thực hiện**:
  1. **Thành viên 1 (Nhóm trưởng)**: [Họ và tên] — MSSV: [Điền MSSV] — Phân mảng: **Mạng & IaC (Network & Infrastructure as Code)**
  2. **Thành viên 2**: [Họ và tên] — MSSV: [Điền MSSV] — Phân mảng: **Tính toán & Container (Compute & Container)**
  3. **Thành viên 3**: [Họ và tên] — MSSV: [Điền MSSV] — Phân mảng: **Dữ liệu & Quản trị tài chính (Database & FinOps)**
  4. **Thành viên 4**: [Họ và tên] — MSSV: [Điền MSSV] — Phân mảng: **Bảo mật & DevSecOps (Security & CI/CD Pipeline)**

---

# MỤC LỤC TỔNG QUAN BÁO CÁO (ĐỘ DÀI DỰ KIẾN: 35 – 45 TRANG)

- **LỜI CẢM ƠN**
- **DANH MỤC THUẬT NGỮ VÀ TỪ VIẾT TẮT**
- **DANH MỤC HÌNH ẢNH & BIỂU ĐỒ**
- **DANH MỤC BẢNG BIỂU**
- **LỜI MỞ ĐẦU**
- **CHƯƠNG 1: TỔNG QUAN ĐỀ TÀI & PHÂN TÍCH YÊU CẦU BÀI TOÁN DOANH NGHIỆP**
  - 1.1. Đặt vấn đề và bối cảnh chuyển dịch đám mây
  - 1.2. Mục tiêu nghiên cứu và phạm vi triển khai
  - 1.3. Phân tích yêu cầu phi chức năng (Non-Functional Requirements)
  - 1.4. Ràng buộc tài chính: Bài toán tối ưu gói tài trợ $200 AWS Credit (FinOps)
  - 1.5. Phân công trách nhiệm và quy chuẩn làm việc Gitflow
- **CHƯƠNG 2: THIẾT KẾ KIẾN TRÚC HỆ THỐNG MẠNG ĐA TẦNG & TỰ ĐỘNG HÓA HẠ TẦNG (IaC)** *(Member 1 phụ trách)*
  - 2.1. Triết lý thiết kế kiến trúc cô lập đa tầng (3-Tier Multi-AZ Architecture)
  - 2.2. Mô hình Dual-VPC và liên kết định tuyến an toàn qua VPC Peering
  - 2.3. Quy hoạch dải địa chỉ IP (CIDR IP Subnet Planning)
  - 2.4. Thiết kế chính sách tường lửa ảo (Security Groups Matrix & Principle of Least Privilege)
  - 2.5. Cân bằng tải ứng dụng Application Load Balancer (ALB) và phân phối CDN CloudFront
  - 2.6. Tự động hóa hạ tầng hoàn toàn bằng Terraform (1-Click Infrastructure Deployment)
- **CHƯƠNG 3: TRIỂN KHAI CÁC PHÂN HỆ CỐT LÕI CỦA NỀN TẢNG**
  - 3.1. Tầng Tính toán & Container hóa ứng dụng (Compute & Container Engine) *(Member 2)*
  - 3.2. Tầng Lưu trữ & Dữ liệu đa mô hình (Relational, NoSQL & Object Storage) *(Member 3)*
  - 3.3. Tầng Giám sát tập trung, Ghi vết API & Quản trị tài chính FinOps *(Member 3)*
  - 3.4. Tầng An ninh ứng dụng & Đường ống CI/CD DevSecOps *(Member 4)*
- **CHƯƠNG 4: KẾT QUẢ THỰC NGHIỆM & DIỄN TẬP KỊCH BẢN DEMO THỰC CHIẾN**
  - 4.1. Môi trường thực nghiệm và thông số bàn giao
  - 4.2. Kịch bản Thực nghiệm 1: Tự phục hồi hạ tầng khi gặp sự cố (Self-Healing Demo)
  - 4.3. Kịch bản Thực nghiệm 2: Phòng thủ an ninh mạng trực chiến với AWS WAFv2 (WAF Defense Demo)
  - 4.4. Kịch bản Thực nghiệm 3: Quản trị chi tiêu thực tế và phân tích FinOps (FinOps Dashboard Demo)
- **CHƯƠNG 5: ĐÁNH GIÁ THEO CHUẨN AWS WELL-ARCHITECTED & BÀI HỌC KINH NGHIỆM**
  - 5.1. Đối chiếu hệ thống với 6 trụ cột của AWS Well-Architected Framework
  - 5.2. Các thách thức kỹ thuật gặp phải và giải pháp xử lý
  - 5.3. Hướng phát triển mở rộng trong tương lai
- **KẾT LUẬN**
- **TÀI LIỆU THAM KHẢO**
- **PHỤ LỤC: MÃ NGUỒN TERRAFORM TRIỂN KHAI TỰ ĐỘNG (IaC SPECIFICATION)**

---

# NỘI DUNG CHI TIẾT TỪNG CHƯƠNG

---

# LỜI MỞ ĐẦU

Trong kỷ nguyên số hóa, hạ tầng điện toán đám mây (Cloud Computing) và văn hóa tích hợp an ninh vào vòng đời phát triển phần mềm (DevSecOps) đã trở thành xương sống cho các hệ thống phần mềm doanh nghiệp hiện đại. Việc xây dựng một hệ thống không chỉ dừng lại ở mức vận hành được ứng dụng, mà đòi hỏi phải giải quyết đồng thời các bài toán cốt lõi: Tính sẵn sàng cao (High Availability), Khả năng chịu lỗi và tự phục hồi (Self-Healing), An ninh phòng thủ đa lớp (Defense in Depth), Tự động hóa toàn diện từ mã nguồn (Infrastructure as Code) và Quản trị tối ưu hóa chi phí (FinOps).

Đồ án **"Enterprise Cloud & DevSecOps Platform"** được xây dựng nhằm mô phỏng toàn diện một nền tảng doanh nghiệp thực thụ trên nền tảng Amazon Web Services (AWS), tuân thủ 100% mô hình Cloud-Native, tự động hóa bằng Terraform và kiểm soát nghiêm ngặt ngân sách sinh viên $200.

---

# CHƯƠNG 1: TỔNG QUAN ĐỀ TÀI & PHÂN TÍCH YÊU CẦU BÀI TOÁN DOANH NGHIỆP

### 1.1. Đặt vấn đề và bối cảnh chuyển dịch đám mây
- Doanh nghiệp truyền thống gặp bài toán máy chủ vật lý tốn kém chi phí đầu tư ban đầu (CapEx), khó co giãn linh hoạt khi có lượng truy cập đột biến và mất nhiều thời gian khôi phục khi phần cứng gặp sự cố.
- Chuyển dịch lên AWS theo mô hình OpEx cho phép thanh toán theo nhu cầu sử dụng thực tế (Pay-as-you-go), tự động co giãn theo tải thực tế và triển khai nhanh chóng trên phạm vi toàn cầu.

### 1.2. Mục tiêu nghiên cứu và phạm vi triển khai
- **Mục tiêu**: Xây dựng kiến trúc 3 tầng chuẩn doanh nghiệp (`Presentation Tier - Logic Tier - Data Tier`) trên 2 Availability Zone (`Multi-AZ`).
- **Phạm vi**: 100% sử dụng dịch vụ AWS Cloud Native (Singapore `ap-southeast-1`), mã hóa toàn bộ hạ tầng bằng Terraform `>= 1.5.0`, xây dựng luồng CI/CD DevSecOps tự động kiểm tra bảo mật hình ảnh và kịch bản WAF ngăn chặn tấn công mạng.

### 1.3. Phân tích yêu cầu phi chức năng (Non-Functional Requirements)
- **Tính sẵn sàng cao (High Availability)**: SLA mục tiêu `>= 99.9%`, hệ thống phân bổ trên ít nhất 2 trung tâm dữ liệu độc lập (Availability Zones: `ap-southeast-1a` và `ap-southeast-1b`).
- **Khả năng tự phục hồi (Self-Healing)**: Khi một máy chủ/task container bị sự cố (chết tiến trình hoặc mất phần cứng), hệ thống phải tự phát hiện qua Health Check của Load Balancer và tự sinh máy mới thay thế trong thời gian dưới 2 phút mà không làm gián đoạn người dùng (Zero Downtime).
- **An ninh bảo mật (Security)**: Áp dụng nguyên tắc đặc quyền tối thiểu (Least Privilege), phân tách mạng cô lập, mã hóa dữ liệu khi lưu trữ (at rest) và khi truyền tải (in transit), ứng dụng không hardcode mật khẩu mà lấy qua AWS Secrets Manager.
- **Khả năng quan sát (Observability)**: Thu thập toàn bộ log và metrics của máy chủ, database và truy vấn mạng về CloudWatch và CloudTrail.

### 1.4. Ràng buộc tài chính: Bài toán FinOps kiểm soát gói tài trợ $200
- **Thách thức**: Nhóm chỉ có ngân sách cố định $200 credit tài trợ sinh viên. Nếu cấu hình sai (bật nhiều NAT Gateway, máy ảo dung lượng lớn, RDS Multi-AZ dư thừa), tài khoản sẽ cạn kiệt chỉ sau vài tuần.
- **Giải pháp FinOps của nhóm**:
  - Tối ưu hóa tầng mạng: Chỉ dùng 1 NAT Gateway với cờ bật/tắt tự động (`enable_nat_gateway = false/true`) giúp tiết kiệm $32.4 USD/tháng.
  - Tối ưu tính toán: Sử dụng `t3.micro` và ECS Fargate cấu hình thấp (0.25 vCPU, 0.5 GB RAM).
  - Tối ưu cơ sở dữ liệu: RDS MySQL `db.t3.micro` Single-AZ với cơ chế snapshot dự phòng thay vì bật Multi-AZ standby đắt tiền trong giai đoạn dev.
  - Cơ chế cảnh báo: Thiết lập AWS Budgets gửi email cảnh báo tự động ở 2 mốc $20 và $50.

### 1.5. Phân công trách nhiệm và quy chuẩn làm việc Gitflow
Bảng phân công chi tiết 4 thành viên theo 4 phân mảng độc lập, tương hỗ:
- **Thành viên 1 (Nhóm trưởng — Mạng & IaC)**: Kiến trúc mạng Dual-VPC, Subnets Multi-AZ, ALB, CloudFront, Route 53, VPC Peering, WAFv2, đóng gói kịch bản Terraform 1-Click.
- **Thành viên 2 (Tính toán & Container)**: Dockerfile, Docker Compose, ECS Fargate, EC2 Auto Scaling, chia sẻ tệp EFS, Lambda xử lý dữ liệu.
- **Thành viên 3 (Dữ liệu & FinOps)**: RDS MySQL, DynamoDB, S3 Lifecycle, CloudWatch Metrics/Alarms, CloudTrail, AWS Budgets, Cost Explorer.
- **Thành viên 4 (Bảo mật & DevSecOps)**: AWS WAF Rules, Secrets Manager, KMS, Cognito User Pool, GitHub Actions CI/CD Pipeline, quét lỗ hổng Trivy Scanner, SQS & SNS.

---

# CHƯƠNG 2: THIẾT KẾ KIẾN TRÚC HỆ THỐNG MẠNG ĐA TẦNG & TỰ ĐỘNG HÓA HẠ TẦNG (IaC)
*(Chương do Thành viên 1 - Nhóm trưởng trực tiếp thiết kế và triển khai)*

### 2.1. Triết lý thiết kế kiến trúc cô lập đa tầng (3-Tier Multi-AZ Architecture)
Hệ thống mạng được phân tách thành 3 tầng độc lập theo chiều ngang và nhân bản đối xứng trên 2 vùng sẵn sàng (`ap-southeast-1a` và `ap-southeast-1b`):
1. **Edge Tier (Tầng rìa mạng - Public Subnets)**:
   - Chứa Internet Gateway (IGW), Application Load Balancer (ALB) và NAT Gateway.
   - Là tầng duy nhất được phép có địa chỉ IP công khai (Public IP) và giao tiếp trực tiếp với Internet bên ngoài.
2. **Compute Tier (Tầng tính toán - Private App Subnets)**:
   - Chứa cụm EC2 Auto Scaling Group và ECS Fargate Tasks chạy logic backend và frontend.
   - Subnet hoàn toàn không có Public IP. Mọi lưu lượng kết nối ra ngoài Internet (kéo docker image, tải bản vá bảo mật) đều phải đi một chiều (`Egress-only`) thông qua NAT Gateway tại Public Subnet.
3. **Database Tier (Tầng dữ liệu - Private DB Subnets)**:
   - Chứa cơ sở dữ liệu quan hệ Amazon RDS MySQL / Aurora.
   - Bị cô lập 100% với Internet (Không có route trỏ ra IGW hay NAT GW). Chỉ cho phép nhận kết nối cổng 3306 từ duy nhất Security Group của Tầng Compute.

### 2.2. Mô hình Dual-VPC và liên kết định tuyến qua VPC Peering
Nhằm đáp ứng yêu cầu quản trị doanh nghiệp nâng cao, nhóm thiết kế 2 Virtual Private Cloud (VPC) độc lập:
- **Production VPC (`10.0.0.0/16`)**: Môi trường chạy các ứng dụng sản xuất, phục vụ người dùng cuối.
- **Management / DevSecOps VPC (`10.1.0.0/16`)**: Môi trường đặt máy chủ Bastion Host (SSH Jump Server), CI/CD Runner và các công cụ giám sát nội bộ.
- **VPC Peering Connection (`pcx-0ec1cc329e47c7ca5`)**: Thiết lập đường hầm định tuyến nội bộ thông suốt hai chiều giữa Production VPC và Management VPC qua giao thức mạng của AWS mà không cần đi qua mạng Internet công cộng.

### 2.3. Quy hoạch dải địa chỉ IP (CIDR IP Subnet Planning)
Bảng quy hoạch chi tiết dải IP mạng doanh nghiệp:

| Tên Subnet | CIDR Block | Availability Zone | Loại Subnet | Chức năng phục vụ |
| :--- | :--- | :---: | :---: | :--- |
| `public-1a` | `10.0.1.0/24` | ap-southeast-1a | Public | Gắn IGW, ALB Node A, NAT Gateway Egress |
| `public-1b` | `10.0.2.0/24` | ap-southeast-1b | Public | Dự phòng Multi-AZ cho ALB Node B |
| `private-app-1a` | `10.0.10.0/24` | ap-southeast-1a | Private App | Triển khai EC2 ASG Node A, ECS Tasks |
| `private-app-1b` | `10.0.11.0/24` | ap-southeast-1b | Private App | Triển khai EC2 ASG Node B, ECS Tasks |
| `private-db-1a` | `10.0.20.0/24` | ap-southeast-1a | Private DB | RDS MySQL Primary Instance (Cách ly 100%) |
| `private-db-1b` | `10.0.21.0/24` | ap-southeast-1b | Private DB | RDS Standby Replica (Multi-AZ Failover) |
| `mgmt-subnet-1a` | `10.1.1.0/24` | ap-southeast-1a | Management | Bastion Host, Quản trị DevOps qua Peering |

### 2.4. Thiết kế chính sách tường lửa ảo (Security Groups Matrix)
Nhóm áp dụng nguyên tắc **Principle of Least Privilege** (Đặc quyền tối thiểu) và **Security Group Chaining** (Nối chuỗi bảo mật dựa trên SG ID thay vì mở dải IP):
- **ALB Security Group**: Chỉ mở cổng `80 (HTTP)` và `443 (HTTPS)` cho toàn bộ Internet (`0.0.0.0/0`).
- **App Security Group**: Chỉ cho phép nhận lưu lượng cổng `3000` với nguồn duy nhất là `ALB Security Group`. Tuyệt đối cấm toàn bộ truy cập trực tiếp từ Internet vào máy chủ ứng dụng.
- **Database Security Group**: Chỉ cho phép nhận lưu lượng cổng `3306 (MySQL)` với nguồn duy nhất là `App Security Group`.
- **EFS Security Group**: Chỉ mở cổng `2049 (NFS)` cho `App Security Group`.
- **Bastion Security Group**: Chỉ cho phép SSH cổng `22` từ địa chỉ IP của Quản trị viên (`admin_ip`).

### 2.5. Cân bằng tải ứng dụng ALB, WAF và CloudFront
- **Application Load Balancer**: Triển khai dạng Public-facing, phân phối lưu lượng đều sang 2 AZ theo thuật toán Round Robin. Target Group cấu hình Health Check liên tục 30 giây/lần tại `/health`.
- **AWS WAFv2 Web ACL**: Gắn trực tiếp lên ALB, bao gồm 3 bộ quy tắc:
  1. *AWSManagedRulesCommonRuleSet*: Chặn XSS, Generic Exploits, Remote File Inclusion.
  2. *AWSManagedRulesSQLiRuleSet*: Chặn đứng các payload khai thác SQL Injection.
  3. *Custom Rate-based Rule*: Chặn IP gửi quá 100 requests/5 phút (Chống DDoS/Brute Force).
- **Amazon CloudFront**: Caching các tài nguyên tĩnh từ S3, tối ưu độ trễ truy cập toàn cầu và giảm tải cho ALB.

### 2.6. Tự động hóa hạ tầng hoàn toàn bằng Terraform (1-Click Deployment)
- Toàn bộ 12 tệp cấu hình `.tf` được tổ chức dạng module hóa cao độ, tách biệt biến (`variables.tf`), giá trị cấu hình (`terraform.tfvars`) và tham số bàn giao (`outputs.tf`).
- Xây dựng 2 bộ scripts tự động hóa:
  - `deploy.ps1` / `deploy.sh`: Kiểm tra xác thực AWS, tự động `init`, `fmt`, `validate`, `plan`, cảnh báo chi phí FinOps, áp dụng hạ tầng và in bảng bàn giao tham số trong dưới 2 phút.
  - `destroy.ps1` / `destroy.sh`: Quy trình dọn dẹp hạ tầng an toàn có cơ chế xác nhận bằng từ khóa `DESTROY`, bảo vệ tuyệt đối hạn mức tài trợ $200.

---

# CHƯƠNG 3: TRIỂN KHAI CÁC PHÂN HỆ CỐT LÕI CỦA NỀN TẢNG
*(Phần khung hướng dẫn cho Member 2, 3, 4 điền chi tiết khi hoàn thành)*

### 3.1. Tầng Tính toán & Container hóa ứng dụng (Compute & Container Engine) *(Member 2)*
- **Đóng gói Docker**: Xây dựng mã nguồn Node.js/Python 3 tầng mẫu, tối ưu hóa kích thước Docker image đa tầng (Multi-stage build).
- **Amazon ECS Fargate**: Triển khai ECS Task Definition chạy mô hình Serverless Container, cấu hình Task Execution IAM Role và kết nối mạng `awsvpc`.
- **Amazon EFS Mount**: Cấu hình chia sẻ ổ đĩa dùng chung giữa các task container thông qua EFS Mount Target tại Private App Subnets.
- **Auto Scaling Group**: Thiết lập chính sách tự động co giãn dựa trên CPU Utilization (Scale out khi CPU > 70%, Scale in khi CPU < 30%).

### 3.2. Tầng Lưu trữ & Dữ liệu đa mô hình *(Member 3)*
- **Amazon RDS MySQL**: Khởi tạo database trong Private DB Subnet Group, thiết lập mã hóa lưu trữ bằng AWS KMS (SSE), cấu hình tự động sao lưu định kỳ (Automated Backups).
- **Amazon DynamoDB**: Lưu trữ dữ liệu phi quan hệ (User Session, Cart) với chế độ On-Demand để tiết kiệm chi phí.
- **Amazon S3 & S3 Glacier**: Lưu trữ dữ liệu tĩnh, cấu hình S3 Lifecycle chuyển tài liệu sang kho lưu trữ lạnh Glacier sau 30 ngày để tối ưu chi phí.

### 3.3. Tầng Giám sát tập trung & Quản trị tài chính FinOps *(Member 3)*
- **Amazon CloudWatch**: Xây dựng Dashboard theo dõi tổng thể: CPU/Memory của ECS/EC2, số lượng request và latency của ALB, số kết nối tới RDS.
- **CloudWatch Alarms & SNS**: Thiết lập cảnh báo tự động gửi email cho nhóm khi máy chủ CPU > 70%.
- **AWS CloudTrail**: Ghi vết 100% các cuộc gọi API trên tài khoản AWS để phục vụ kiểm toán an ninh.
- **AWS Budgets & Cost Explorer**: Minh chứng kiểm soát chi tiêu $200 qua biểu đồ phân tích hàng tuần.

### 3.4. Tầng An ninh ứng dụng & Đường ống CI/CD DevSecOps *(Member 4)*
- **AWS Secrets Manager & KMS**: Mã hóa chuỗi kết nối Database và Secrets, ứng dụng tự động gọi SDK lấy mật khẩu mà không hardcode vào Git.
- **Amazon Cognito**: Tạo User Pool quản lý đăng ký, đăng nhập và cấp phát JWT Token an toàn.
- **Đường ống GitHub Actions CI/CD**:
  - Tự động chạy Unit Test và Smoke Test khi có commit mới.
  - Tích hợp công cụ **Trivy Scanner** tự động quét lỗ hổng bảo mật của Docker image và xuất báo cáo SARIF lên tab GitHub Security.
  - Sử dụng cơ chế xác thực **GitHub OIDC (Zero Secret Keys)** để đăng nhập và đẩy ảnh lên Amazon ECR an toàn tuyệt đối.

---

# CHƯƠNG 4: KẾT QUẢ THỰC NGHIỆM & DIỄN TẬP KỊCH BẢN DEMO THỰC CHIẾN

### 4.1. Môi trường thực nghiệm và thông số bàn giao
Nhóm đã triển khai thành công hạ tầng trên vùng `ap-southeast-1` với các thông số bàn giao kỹ thuật thực tế:
- **VPC ID**: `vpc-0adbecc6d58dd7b02` (CIDR: `10.0.0.0/16`)
- **ALB DNS**: `enterprise-cloud-devsecops-alb-1849030400.ap-southeast-1.elb.amazonaws.com`
- **CloudFront Domain**: `d28q9aeiublqqm.cloudfront.net`
- **VPC Peering ID**: `pcx-0ec1cc329e47c7ca5` (Status: `Active`)
- **Minh chứng triển khai**: *Đính kèm Hình 1 (Terminal Deploy) và Hình 2 (VPC Resource Map)*.

### 4.2. Kịch bản Thực nghiệm 1: Tự phục hồi hạ tầng (Self-Healing Demo)
- **Quy trình thực hiện**:
  1. Trình duyệt mở trang web đang chạy bình thường qua tên miền ALB (HTTP 200 OK).
  2. Quản trị viên vào AWS Console bấm cưỡng bức tắt (`Stop` hoặc `Terminate`) 1 instance/task.
  3. Người dùng liên tục ấn F5 trên trình duyệt: Trang web **vẫn hoạt động 100% không bị gián đoạn**, do ALB lập tức loại bỏ node lỗi ra khỏi Target Group và điều hướng toàn bộ traffic sang node còn sống ở AZ còn lại.
  4. Sau 90 giây, Auto Scaling Group / ECS tự động sinh ra node mới thay thế, đưa hệ thống trở lại trạng thái cân bằng hoàn toàn.

### 4.3. Kịch bản Thực nghiệm 2: Phòng thủ an ninh mạng với AWS WAF (WAF Defense Demo)
- **Quy trình thực hiện**:
  - Gửi request bình thường:
    ```bash
    curl.exe -i "http://<alb-dns-name>/"
    # Phản hồi: HTTP/1.1 200 OK
    ```
  - Gửi payload tấn công SQL Injection:
    ```bash
    curl.exe -i "http://<alb-dns-name>/users?id=%27%20OR%201=1%20--"
    # Phản hồi: HTTP/1.1 403 Forbidden (Bị WAF chặn đứng ngay tại rìa ALB!)
    ```
- **Minh chứng**: *Đính kèm Hình 3 (Terminal curl WAF 403 Forbidden)*.

### 4.4. Kịch bản Thực nghiệm 3: Quản trị chi tiêu thực tế FinOps
- **Kết quả đo đạc trên AWS Billing**:
  - Sau 6 tuần triển khai và thử nghiệm, tổng chi phí thực tế ghi nhận trên AWS Billing chỉ là **$9.82 USD** trên tổng hạn mức tài trợ **$200.00 USD**.
  - Trạng thái AWS Budgets: `Health Status: Healthy`, `Thresholds: OK` (không có cảnh báo vi phạm).
- **Minh chứng**: *Đính kèm Hình 4 (Giao diện AWS Budgets $200 & Amount $9.82)*.

---

# CHƯƠNG 5: ĐÁNH GIÁ THEO CHUẨN AWS WELL-ARCHITECTED & BÀI HỌC KINH NGHIỆM

### 5.1. Đối chiếu hệ thống với 6 trụ cột của AWS Well-Architected Framework
1. **Operational Excellence (Vận hành xuất sắc)**: Toàn bộ hạ tầng được mô tả bằng mã nguồn Terraform, triển khai và dọn dẹp bằng script 1 lệnh, CI/CD tự động hóa kiểm thử và quét mã.
2. **Security (An ninh bảo mật)**: Phòng thủ đa tầng với AWS WAFv2, Security Group Chaining, mạng cô lập không Public IP cho Database, Secrets Manager chống lộ thông tin nhạy cảm.
3. **Reliability (Độ tin cậy)**: Kiến trúc Multi-AZ phân bổ qua 2 trung tâm dữ liệu độc lập, cơ chế Self-Healing khôi phục dịch vụ tự động dưới 2 phút.
4. **Performance Efficiency (Hiệu năng)**: Sử dụng CloudFront CDN phân phối tài nguyên tĩnh toàn cầu, ALB phân bổ tải đồng đều.
5. **Cost Optimization (Tối ưu chi phí)**: Áp dụng tư duy FinOps thực chiến: Sử dụng 1 NAT Gateway với công tắc bật/tắt, lựa chọn cấu hình t3.micro/Fargate tiết kiệm, duy trì chi phí thực tế dưới $10 sau 6 tuần.
6. **Sustainability (Tính bền vững)**: Tự động thu hồi tài nguyên không sử dụng sau các buổi kiểm thử (`destroy.ps1`), giảm thiểu lãng phí tài nguyên đám mây.

### 5.2. Các thách thức kỹ thuật gặp phải và giải pháp xử lý
- *Thách thức 1 (State Lock trong CI/CD)*: Khi chạy nhiều commit cùng lúc, Terraform bị kẹt khóa DynamoDB -> Giải pháp: Cấu hình `concurrency: cancel-in-progress: true` và cờ `-lock=false` cho các job plan kiểm thử trong CI.
- *Thách thức 2 (Smoke test backend khi chưa có database)*: Endpoint `/health` bị crash làm fail pipeline CI -> Giải pháp: Tách biệt kiểm tra tiến trình ứng dụng (liveness) và kiểm tra kết nối cơ sở dữ liệu (readiness), trả về cảnh báo an toàn.
- *Thách thức 3 (Xung đột phụ thuộc khi dọn dẹp hạ tầng)*: Ổ đĩa EFS giữ điểm kết nối khiến Subnet không xóa được -> Giải pháp: Xây dựng quy trình hủy mount target trước khi thu hồi subnet.

### 5.3. Hướng phát triển mở rộng trong tương lai
- Nâng cấp triển khai ứng dụng lên cụm Kubernetes sử dụng **Amazon EKS (Elastic Kubernetes Service)**.
- Tích hợp công cụ phân tích bảo mật tĩnh mã nguồn (SAST) như SonarQube vào pipeline CI/CD.
- Thiết lập giải pháp Disaster Recovery (DR) đa vùng địa lý (Multi-Region Active-Passive).

---

# KẾT LUẬN

Sau 7 tuần nghiên cứu và triển khai, nhóm sinh viên đã hoàn thành 100% các mục tiêu đề ra cho đồ án **Enterprise Cloud & DevSecOps Platform**. Hệ thống đã chứng minh được tính đúng đắn và hiệu quả trong việc kết hợp giữa kiến trúc đám mây đa tầng chịu lỗi cao, quy trình tự động hóa hạ tầng IaC và các nguyên tắc bảo mật DevSecOps thực chiến. 

Đặc biệt, đồ án khẳng định tư duy quản trị tài chính FinOps xuất sắc khi vận hành toàn bộ hệ sinh thái phức tạp mà vẫn duy trì mức chi tiêu thực tế tối ưu dưới $10 USD, bảo toàn trọn vẹn gói tài trợ $200 của nhà trường. Kết quả của đồ án là nền tảng vững chắc để các thành viên trong nhóm tự tin bước vào môi trường kỹ thuật thực tế tại các doanh nghiệp công nghệ lớn.

---

# PHỤ LỤC: MÃ NGUỒN TERRAFORM THAM KHẢO
*(Đính kèm danh mục các tệp `vpc.tf`, `subnets.tf`, `security_groups.tf`, `alb.tf`, `waf.tf`, `vpc_peering.tf`, `outputs.tf` và bộ scripts `deploy.ps1`/`destroy.ps1`)*
