# BẢNG MA TRẬN PHÂN QUYỀN IAM LEAST PRIVILEGE (RBAC MATRIX)

> **Dự án**: ENTERPRISE CLOUD & DEVSECOPS PLATFORM  
> **Tác giả phụ trách**: Thành viên 3 (Dữ liệu & FinOps - Phạm Thế Hùng)  
> **Nguyên tắc cốt lõi**: `Principle of Least Privilege (PoLP)` — Mỗi thành viên chỉ sở hữu đúng tập quyền tối thiểu phục vụ cho chuyên môn được giao, ngăn chặn việc can thiệp trái phép, xung đột tài nguyên và kiểm soát chi phí tối đa ($200 Credit).

---

## 1. TỔNG QUAN PHÂN VAI & ĐỊNH DANH (IDENTITIES & TRACK ROLES)

| Vai trò | Tên IAM Group | Tên IAM User | Phân mảng đảm nhiệm | Trách nhiệm cốt lõi |
| :--- | :--- | :--- | :--- | :--- |
| **Thành viên 1** | `Network-IaC-Group` | `member1-network-iac` | **Mạng & IaC** | Dựng Production VPC, Subnets Multi-AZ, IGW, NAT GW, ALB, Route 53, CloudFront, Peering |
| **Thành viên 2** | `Compute-Container-Group` | `member2-compute-container` | **Tính toán & Container** | Triển khai EC2 Auto Scaling, ECS Fargate, ECR, EFS, Lambda, Elastic Beanstalk / Lightsail |
| **Thành viên 3** | `Data-FinOps-Group` | `member3-data-finops` | **Dữ liệu & FinOps** | Quản trị RDS MySQL/Aurora, DynamoDB, S3, Glacier, Redshift, CloudWatch, AWS Budgets, Cost Explorer |
| **Thành viên 4** | `Security-DevSecOps-Group` | `member4-security-devsecops` | **Bảo mật & DevSecOps** | Cấu hình AWS WAF, Secrets Manager, KMS, Cognito User Pool, SQS, SNS, IAM roles CI/CD |

---

## 2. MA TRẬN ÁNH XẠ DỊCH VỤ AWS & QUYỀN HẠN (SERVICE-LEVEL PERMISSIONS)

> **Ký hiệu**:
> - `FULL` : Toàn quyền cấu hình, khởi tạo, sửa đổi và hủy tài nguyên trong phạm vi dịch vụ.
> - `LIMITED`: Chỉ được phép thực hiện các thao tác chuyên biệt cần thiết (ví dụ: gắn WAF vào ALB, hoặc truyền Role).
> - `READ` : Chỉ có quyền xem thông số (Describe/Get/List) để phục vụ tích hợp chéo.
> - `DENY` : Hoàn toàn không có quyền truy cập hoặc thực thi lệnh (Mặc định bị chặn theo PoLP).

| Dịch vụ AWS | Member 1 (Mạng & IaC) | Member 2 (Compute) | Member 3 (Data & FinOps) | Member 4 (Security) | Cơ sở & Giải thích lý do phân quyền |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **VPC, Subnets, Routing** | **FULL** | READ | READ | READ | Member 1 nắm độc quyền kiến trúc mạng nền tảng để tránh xung đột IP CIDR. |
| **Security Groups** | **FULL** | READ | READ | READ | Member 1 quản lý toàn bộ quy tắc mở cổng giữa các tầng Web, App và DB. |
| **Elastic Load Balancer (ALB)** | **FULL** | LIMITED (Register TG) | DENY | READ | Member 1 tạo ALB, Member 2 chỉ đăng ký Target Group của ECS container. |
| **Route 53 & CloudFront** | **FULL** | READ | READ | READ | Tầng phân phối toàn cầu và phân giải DNS thuộc trách nhiệm Member 1. |
| **EC2 & Auto Scaling** | READ | **FULL** | DENY | DENY | Member 2 quản trị vòng đời máy chủ ứng dụng và chính sách co giãn tải. |
| **ECS, Fargate & ECR** | READ | **FULL** | DENY | LIMITED (CI/CD push) | Member 2 quản lý container workload; Member 4 có quyền push ảnh từ CI/CD. |
| **Elastic File System (EFS)** | DENY | **FULL** | DENY | DENY | Hệ thống tệp chia sẻ cho ECS và EC2 do Member 2 triển khai. |
| **Lambda & Beanstalk** | DENY | **FULL** | DENY | DENY | Xử lý ảnh không máy chủ và môi trường staging phụ trợ của Member 2. |
| **RDS MySQL / Aurora** | READ (Subnet Group) | READ (Endpoint) | **FULL** | DENY | Member 3 chịu trách nhiệm toàn bộ cơ sở dữ liệu quan hệ lõi. |
| **Amazon DynamoDB** | DENY | READ/WRITE | **FULL** | DENY | Member 3 tạo bảng & cấu hình; ứng dụng của Member 2 ghi session/cart. |
| **Amazon S3 & Glacier** | LIMITED (TF State) | READ/WRITE (Assets) | **FULL** | DENY | Member 3 quản lý Bucket chính, phân tầng Glacier và chính sách vòng đời. |
| **Redshift Serverless** | DENY | DENY | **FULL** | DENY | Cụm phân tích dữ liệu chuyên sâu do Member 3 demo và tắt dọn dẹp. |
| **CloudWatch & CloudTrail** | READ | READ | **FULL** | READ | Member 3 là trung tâm giám sát hạ tầng và ghi vết kiểm toán toàn hệ thống. |
| **AWS Budgets & Cost Explorer** | READ | READ | **FULL** | READ | Member 3 thiết lập các mốc cảnh báo $20/$50 và báo cáo tài chính FinOps. |
| **AWS WAF (Web ACLs)** | LIMITED (Associate ALB) | DENY | DENY | **FULL** | Member 4 thiết kế bộ luật chống SQLi/XSS; Member 1 chỉ gắn vào ALB. |
| **Secrets Manager & KMS** | DENY | READ (GetSecretValue) | DENY | **FULL** | Member 4 quản lý khóa mã hóa và mật khẩu DB; Member 2 gọi API lấy lúc runtime. |
| **Amazon Cognito** | DENY | READ (Pool ID) | DENY | **FULL** | Tầng xác thực người dùng và cấp phát JWT token do Member 4 phụ trách. |
| **Amazon SQS & SNS** | DENY | READ/WRITE (Send/Recv) | DENY | **FULL** | Kiến trúc tin nhắn hướng sự kiện Event-Driven do Member 4 thiết lập. |
| **IAM Policy & User Mgmt** | DENY | DENY | **FULL (Week 1)** | LIMITED (CI/CD Role) | Member 3 khởi tạo nền tảng IAM; Member 4 tạo IAM Role cho GitHub Actions. |

---

## 3. CHÍNH SÁCH BẢO VỆ CHUNG (COMMON BASE POLICY)
Cả 4 tài khoản người dùng đều bắt buộc tuân theo chính sách an ninh chung:
1. **Self-Service Credentials**: Mỗi thành viên tự đổi mật khẩu cá nhân định kỳ (tối thiểu 12 ký tự, bắt buộc đủ chữ hoa, chữ thường, số, ký tự đặc biệt).
2. **MFA Enforcement**: Bắt buộc cấu hình thiết bị xác thực 2 lớp (Virtual MFA - Google Authenticator / Authy) ngay trong lần đầu đăng nhập.
3. **FinOps Visibility**: Mọi thành viên đều được cấp quyền xem (`ViewBudget` & `GetCostAndUsage`) để chủ động theo dõi chi phí sử dụng của phần việc mình phụ trách, tuyệt đối không lãng phí ngân sách $200.
4. **No Destructive Root Actions**: Ngăn chặn tuyệt đối quyền xóa tài khoản gốc AWS, tắt MFA của tài khoản root hoặc sửa đổi thông tin thanh toán tín dụng.
