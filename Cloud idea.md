# TỔNG QUAN DỰ ÁN: ENTERPRISE CLOUD & DEVSECOPS PLATFORM

_(Nền tảng Ứng dụng Doanh nghiệp Đa tầng trên AWS tích hợp Tự động hóa & An ninh mạng)_

### 1. Ý tưởng cốt lõi và Mục tiêu dự án

- **Mô hình kiến trúc:** Xây dựng cổng thông tin và nền tảng dịch vụ doanh nghiệp đa tầng (`3-Tier Architecture`), kết hợp giữa `Monolith Web Application (ứng dụng web nguyên khối)` và `Microservices (kiến trúc vi dịch vụ)` chạy trên môi trường đa vùng khả dụng (`Multi-AZ - Multi-Availability Zone`).
    
- **Mục tiêu học thuật:** Khai thác thực tế 100% các nhóm dịch vụ trong đề cương học phần trên tài khoản AWS thật (tận dụng gói học sinh $200). Chuyển đổi phần `OpenStack (nền tảng đám mây riêng mã nguồn mở)` thành chuyên đề **Phân tích Kiến trúc Mở rộng Đám mây lai trên Lý thuyết (`Proposed Hybrid Cloud Architecture`)** trong báo cáo để tối ưu tài nguyên phần cứng máy tính cá nhân.
    
- **Mục tiêu điểm số:** Giành trọn vẹn điểm đồ án chính khóa và tối đa hóa điểm cộng (`Bonus Points`) nhờ tích hợp sâu các tiêu chuẩn doanh nghiệp:
    
    - `Infrastructure as Code - IaC (hạ tầng dưới dạng mã nguồn)` bằng Terraform.
        
    - `CI/CD Pipeline (đường ống tích hợp và triển khai liên tục)` tự động quét lỗ hổng an ninh (`DevSecOps`).
        
    - `Application Layer Defense (phòng thủ tầng ứng dụng)` với AWS WAF.
        
    - `Event-Driven Architecture (kiến trúc hướng sự kiện)` bất đồng bộ với Amazon SQS và Amazon SNS.
        
    - `High Availability & Self-Healing (độ sẵn sàng cao và khả năng tự phục hồi)`.
        

### 2. Thiết kế Kiến trúc Hệ thống (System Architecture)

Toàn bộ hệ thống được triển khai trên nền tảng AWS và phân tách độc lập qua 2 đám mây riêng ảo (`Multi-VPC Architecture`) kết nối thông suốt qua `VPC Peering`:

Plaintext

```
[ Người dùng / Khách hàng ]
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
│  ├── EC2 Auto Scaling Group (Cụm máy chủ web tự co giãn theo tải CPU)               │
│  ├── Amazon ECS + AWS Fargate (Microservices container chạy ngầm không máy chủ)     │
│  └── Amazon EFS (Hệ thống tệp mạng chia sẻ dùng chung giữa các container/máy chủ)   │
│                                                                                     │
│  [ Private Subnets - Tầng Dữ liệu (Database Tier - Cách ly hoàn toàn) ]              │
│  ├── Amazon Aurora Serverless / RDS MySQL Multi-AZ (Cơ sở dữ liệu giao dịch chính)  │
│  └── Amazon DynamoDB (NoSQL lưu trữ phiên làm việc User Session và Giỏ hàng tạm)    │
│                                                                                     │
│  [ Tầng Lưu trữ Đối tượng (Object Storage Tier) ]                                   │
│  ├── Amazon S3 (Lưu trữ ảnh đại diện, giao diện tĩnh, tài liệu tải lên)             │
│  └── S3 Glacier (Lưu trữ chứng từ, hóa đơn kế toán cũ theo chính sách vòng đời)     │
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
│  • Amazon Cognito: Cung cấp xác thực đăng ký/đăng nhập và cấp phát JWT Token        │
│  • Amazon SQS & SNS: Hàng đợi và thông báo sự kiện giao dịch/thanh toán bất đồng bộ │
│  • GitHub Actions Runner + Trivy: Tự động kiểm thử mã nguồn và quét lỗ hổng bảo mật │
│                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘
                                           │
            [ KẾT NỐI MỞ RỘNG TRÊN BÁO CÁO LÝ THUYẾT (THEORETICAL DESIGN) ]
                                           │ (AWS Site-to-Site VPN / IPsec)
                                           ▼
┌────────────────────────── OpenStack Private Cloud (On-Premises) ────────────────────┐
│  • Neutron: Mạng ảo định tuyến sang AWS VPC qua VPN tunnel                          │
│  • Nova & Cinder: Máy chủ ảo nội bộ xử lý đối soát chứng từ tài chính               │
│  • Horizon Dashboard: Bảng điều khiển quản trị hạ tầng đám mây riêng                │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### 3. Bản đồ Ánh xạ 100% Danh mục Dịch vụ Học phần trên AWS

Dạ, thưa tổng tài, bảng cấu trúc đảm bảo bao phủ đầy đủ tất cả các dịch vụ trong syllabus (đề cương môn học) mà không bỏ sót bất kỳ hạng mục nào:

|**Phân nhóm dịch vụ**|**Dịch vụ trong đề cương**|**Vai trò cụ thể trong Dự án**|**Trạng thái triển khai**|
|---|---|---|---|
|**1. Tính toán (`Compute`)**|`EC2`, `Auto Scaling`, `ECS`, `Fargate`, `ECR`, `Lambda`, `Elastic Beanstalk`, `Batch`, `Lightsail`|• `ECS + Fargate + ECR`: Chạy container microservice nghiệp vụ bằng Docker.<br><br>  <br><br>• `EC2 + Auto Scaling`: Chạy web chính, tự co giãn và tự phục hồi khi máy chủ sập.<br><br>  <br><br>• `Lambda`: Tự động nén ảnh đại diện khi người dùng tải lên S3.<br><br>  <br><br>• `Beanstalk & Lightsail`: Dựng môi trường staging/blog tin tức phụ trợ.<br><br>  <br><br>• `AWS Batch`: Chạy tiến trình kết xuất báo cáo dữ liệu định kỳ.|🟢 Deploy thật trên AWS (Bật/tắt linh hoạt)|
|**2. Lưu trữ (`Storage`)**|`S3`, `S3 Glacier`, `EBS`, `EFS`|• `S3`: Lưu trữ tài nguyên tĩnh (ảnh, CSS, Javascript).<br><br>  <br><br>• `S3 Glacier`: Cấu hình `Lifecycle Policy` tự động chuyển hóa đơn cũ sau 30 ngày.<br><br>  <br><br>• `EBS`: Ổ đĩa hệ điều hành tốc độ cao cho EC2.<br><br>  <br><br>• `EFS`: Thư mục chia sẻ tệp chung giữa các container ECS.|🟢 Deploy thật trên AWS|
|**3. Cơ sở dữ liệu (`Database`)**|`RDS`, `Aurora`, `DynamoDB`, `Redshift`|• `RDS MySQL / Aurora Serverless`: Lưu tài khoản, danh mục sản phẩm, đơn hàng.<br><br>  <br><br>• `DynamoDB`: Lưu giỏ hàng tạm thời và `User Session (phiên người dùng)`.<br><br>  <br><br>• `Redshift`: Tạo 1 cụm Serverless truy vấn phân tích dữ liệu (bật 1 giờ demo rồi xóa).|🟢 Deploy thật trên AWS (Tối ưu giờ chạy)|
|**4. Mạng & Phân phối (`Networking`)**|`VPC`, `ELB (ALB)`, `Route 53`, `CloudFront`, `VPC Peering`, `Transit Gateway`, `Direct Connect`, `Outposts`|• `VPC Multi-AZ + ALB`: Phân tách Public/Private Subnet và cân bằng tải.<br><br>  <br><br>• `CloudFront + Route 53`: Tối ưu hóa bộ nhớ đệm `Caching` và phân giải DNS.<br><br>  <br><br>• `VPC Peering`: Kết nối bảo mật nội bộ giữa Production VPC và Management VPC.<br><br>  <br><br>• `Direct Connect & Outposts`: Đưa vào chương phân tích đối chiếu giải pháp lớn trong báo cáo.|🟢 Deploy thật (VPC, ALB, CloudFront, Peering) + 🔵 Architecture lý thuyết|
|**5. Bảo mật & Danh tính (`Security`)**|`IAM`, `Cognito`, `AWS WAF`, `Secrets Manager`, `KMS`, `Shield`, `Artifact`|• `IAM`: Phân quyền người dùng theo `Principle of Least Privilege`.<br><br>  <br><br>• `Cognito`: Quản lý xác thực đăng ký/đăng nhập và cấp phát mã JWT.<br><br>  <br><br>• `AWS WAF`: Tường lửa chặn đứng SQL Injection, XSS và Rate Limiting.<br><br>  <br><br>• `Secrets Manager + KMS`: Quản lý và mã hóa mật khẩu DB, loại bỏ hardcode.<br><br>  <br><br>• `Shield & Artifact`: Bật bảo vệ chống DDoS cơ bản và xuất chứng chỉ tuân thủ SOC2.|🟢 Deploy thật trên AWS|
|**6. Quản trị & Chi phí (`Governance & Cost`)**|`CloudWatch`, `CloudTrail`, `Config`, `Well-Architected Tool`, `AWS Budgets`, `Cost Explorer`|• `CloudWatch`: Giám sát chỉ số CPU/RAM, thiết lập chuông cảnh báo quá tải.<br><br>  <br><br>• `CloudTrail`: Ghi vết toàn bộ hành vi gọi API quản trị hạ tầng.<br><br>  <br><br>• `AWS Budgets`: Thiết lập ngưỡng cảnh báo email tự động khi vượt $20.<br><br>  <br><br>• `Well-Architected Tool`: Đánh giá dự án theo 6 trụ cột tối ưu của AWS.|🟢 Deploy thật trên AWS|
|**7. Đám mây lai (`Hybrid Cloud`)**|`OpenStack (Nova, Neutron, Cinder, Horizon, Keystone)`|Phân tích giải pháp kết nối `Site-to-Site VPN` giữa AWS VPC và Neutron OpenStack; lập bảng đối chiếu tương đương giữa các dịch vụ AWS và OpenStack.|🔵 Architecture & Report (Phân tích lý thuyết sâu trong báo cáo đồ án)|

### 4. Năm tính năng "Vũ khí bí mật" lấy trọn điểm cộng (Bonus Points)

1. **Hạ tầng dưới dạng mã nguồn (`IaC with Terraform`)**:
    
    - Toàn bộ tài nguyên mạng (VPC, Subnet, Route Table, Internet Gateway, NAT Gateway), máy chủ và cơ sở dữ liệu được mã hóa thành các kịch bản `.tf`.
        
    - Nhóm chứng minh khả năng tự động hóa hạ tầng hoàn toàn: chỉ cần gõ đúng 1 lệnh `terraform apply` là toàn bộ hệ thống được khởi tạo chuẩn xác trong 3–5 phút.
        
2. **Quy trình tích hợp bảo mật tự động (`DevSecOps & CI/CD Pipeline`)**:
    
    - Sử dụng `GitHub Actions`. Mỗi khi thành viên đẩy mã nguồn mới lên nhánh chính (`main`), đường ống tự động kích hoạt:
        
        - Chạy kiểm thử mã nguồn (`Unit Tests`).
            
        - Tự động quét lỗ hổng bảo mật của ảnh container bằng công cụ `Trivy Scanner`.
            
        - Đẩy ảnh container sạch lên `Amazon ECR` và kích hoạt triển khai lên máy chủ.
            
3. **Phòng thủ tầng ứng dụng bằng `AWS WAF (Web Application Firewall)`**:
    
    - Gắn WAF trực tiếp trước bộ cân bằng tải ALB.
        
    - Thiết lập bộ luật tùy biến: Chặn tấn công `SQL Injection (chèn mã SQL độc)`, Chặn `XSS (tấn công kịch bản chéo)` và Kích hoạt `Rate Limiting (giới hạn tối đa 100 requests / 5 phút trên mỗi IP để chống spam/DDoS)`.
        
4. **Bảo mật thông tin đăng nhập với `AWS Secrets Manager & KMS`**:
    
    - Tuyệt đối không lưu trữ cứng thông tin tài khoản hay mật khẩu cơ sở dữ liệu trong mã nguồn (`No Hardcoded Credentials`).
        
    - Ứng dụng khi khởi động sẽ tự động gọi API an toàn đến Secrets Manager để lấy thông tin đăng nhập, dữ liệu được mã hóa bằng khóa bảo mật riêng từ `AWS KMS`.
        
5. **Kiến trúc hướng sự kiện bất đồng bộ (`Event-Driven Architecture`)**:
    
    - Sử dụng kết hợp `Amazon SQS (hàng đợi thông báo)` và `Amazon SNS (dịch vụ phân phối thông báo)`.
        
    - Khi người dùng thực hiện giao dịch hoặc nộp tác vụ nặng, hệ thống đẩy sự kiện vào hàng đợi SQS để xử lý nền và kích hoạt SNS gửi email xác nhận tức thì, giúp tách rời các thành phần và tối ưu hóa tốc độ phản hồi của trang web.
        

### 5. Dự toán Ngân sách Chi tiết từ Gói Tài trợ $200

Dạ, thưa tổng tài, để duy trì hệ thống chạy phục vụ kiểm thử, chụp ảnh minh chứng và bảo vệ đồ án trong suốt quá trình làm việc, chi phí ước tính được kiểm soát chặt chẽ như sau:

- **NAT Gateway (1 bộ duy nhất):** ~$15 – $20 (khoảng $0.045/giờ, tắt khi không dùng).
    
- **Application Load Balancer (ALB):** ~$12 – $15.
    
- **Amazon Aurora Serverless v2 / RDS MySQL (db.t3.micro):** ~$10 – $15.
    
- **Amazon EC2 (t3.micro) + ECS Fargate:** ~$8 – $12.
    
- **AWS WAF + Secrets Manager + KMS:** ~$5.
    
- **Redshift Serverless (chỉ bật chạy demo truy vấn 1–2 giờ rồi xóa cụm):** ~$1.
    
- **Tài nguyên miễn phí (Free Tier):** S3 (dưới 5GB), DynamoDB (dưới 25GB), Lambda (1 triệu requests/tháng), CloudWatch cơ bản.
    
- **👉 Tổng chi phí dự kiến:** Khoảng **$50 – $65 USD**. Tài khoản vẫn còn dư dôi an toàn từ **$135 – $150 USD**.
    

### 6. Kịch bản Trình diễn Thực tế (Demo Script) Trước Hội đồng Chấm thi

Khi bước vào phòng bảo vệ, nhóm tổng tài sẽ trình diễn 3 màn demo thực chiến trực tiếp trên màn hình chiếu:

- **Màn 1: Trình diễn Khả năng Tự phục hồi (`Self-Healing`)**
    
    - Mở trang web ứng dụng đang hoạt động bình thường trên trình duyệt.
        
    - Mở song song AWS Console, chủ động bấm **Terminate (Xóa cưỡng bức)** 1 máy chủ EC2 hoặc tắt một Container Task đang chạy.
        
    - Nhấn F5 trang web để chứng minh dịch vụ không hề bị gián đoạn (Zero-Downtime) nhờ ALB tự động chuyển hướng sang máy chủ phụ. Chỉ 1 phút sau, mở giao diện Auto Scaling Group để giảng viên tận mắt chứng kiến hệ thống tự sinh ra một máy chủ mới thay thế.
        
- **Màn 2: Trình diễn Phòng thủ Tấn công Thực tế với AWS WAF**
    
    - Mở Terminal, thực thi lệnh `curl` gửi yêu cầu đính kèm payload tấn công SQL Injection: `' OR 1=1 --`.
        
    - Màn hình Terminal lập tức trả về mã phản hồi `403 Forbidden` (bị WAF chặn đứng).
        
    - Chuyển sang giao diện AWS CloudWatch / WAF Console, chỉ cho hội đồng thấy biểu đồ lưu lượng mạng vừa ghi nhận và triệt hạ một cuộc tấn công trái phép theo thời gian thực.
        
- **Màn 3: Trình diễn Tự động hóa & Năng lực Quản trị Chi phí (`IaC & FinOps`)**
    
    - Mở giao diện `GitHub Actions` chứng minh đường ống CI/CD tự động chạy kiểm thử và quét sạch mã độc của Docker Image bằng `Trivy Scanner` trước khi deploy.
        
    - Trình chiếu thư mục mã nguồn `Terraform` đã chuẩn hóa toàn bộ hạ tầng.
        
    - Mở bảng điều khiển `AWS Cost Explorer` và `AWS Budgets` để chứng minh nhóm có tư duy quản trị tài chính đám mây chuyên nghiệp, kiểm soát hệ thống chạy mượt mà mà chỉ tiêu tốn một phần nhỏ ngân sách.
        

### 7. Phân công Trách nhiệm 4 Thành viên (Khối lượng Độc lập & Đồng đều)

Dạ, thưa tổng tài, 4 phân mảng được phân bổ rành mạch để mỗi thành viên chịu trách nhiệm trọn gói một nhánh công việc mà không bị phụ thuộc vào nhau:

1. **Thành viên 1 — Tổng tài (Mạng, Hạ tầng IaC & Trưởng nhóm):**
    
    - _Nhiệm vụ:_ Viết toàn bộ mã nguồn Terraform, thiết lập kiến trúc VPC Multi-AZ, cấu hình Security Group, Route 53, CloudFront và kết nối Multi-VPC Peering.
        
    - _Trách nhiệm demo:_ Trình diễn mã nguồn Terraform và sơ đồ mạng kết nối đa tầng.
        
2. **Thành viên 2 (Tính toán & Containerization):**
    
    - _Nhiệm vụ:_ Đóng gói ứng dụng web 3 tầng vào Docker, triển khai cụm ECS Fargate, cấu hình EC2 Auto Scaling Group sau ALB, gắn ổ đĩa chia sẻ EFS và chạy thử nghiệm Lambda/Beanstalk.
        
    - _Trách nhiệm demo:_ Trực tiếp thực hiện màn demo **Self-Healing** (tắt máy chủ trước mặt hội đồng).
        
3. **Thành viên 3 (Dữ liệu, Giám sát & Quản trị Chi phí FinOps):**
    
    - _Nhiệm vụ:_ Khởi tạo RDS MySQL/Aurora Serverless, bảng DynamoDB, cấu hình S3 Lifecycle chuyển sang S3 Glacier, thiết lập CloudWatch Dashboard/Alarms và quản lý hạn mức AWS Budgets.
        
    - _Trách nhiệm demo:_ Trực tiếp thực hiện màn demo **FinOps & Monitoring** (phân tích biểu đồ chi phí và cảnh báo quá tải).
        
4. **Thành viên 4 (Bảo mật, DevSecOps & Kiến trúc Hướng sự kiện):**
    
    - _Nhiệm vụ:_ Thiết lập bộ luật AWS WAF, cấu hình AWS Secrets Manager + KMS, tích hợp xác thực Amazon Cognito, dựng GitHub Actions Pipeline quét Trivy và tích hợp SQS/SNS.
        
    - _Trách nhiệm demo:_ Trực tiếp thực hiện màn demo **WAF Defense** (bắn lệnh curl tấn công SQLi).