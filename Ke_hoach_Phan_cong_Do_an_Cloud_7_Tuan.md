# DỰ ÁN CLOUD: ENTERPRISE CLOUD & DEVSECOPS PLATFORM
> **Mục tiêu**: Xây dựng nền tảng ứng dụng doanh nghiệp đa tầng (`3-Tier Architecture`), tự động hóa hạ tầng bằng Terraform (`IaC`), tích hợp đường ống `CI/CD DevSecOps`, tường lửa ứng dụng `AWS WAF`, và kiểm soát ngân sách $200 credit.

---

## 1. THÔNG TIN CHUNG & QUY CHUẨN LÀM VIỆC

- **Quy mô**: 4 thành viên.
- **Thời lượng**: 7 tuần (Tuần 1 đến Tuần 7).
- **Môi trường**: 100% AWS Cloud Native (Không cài đặt OpenStack trên máy cá nhân).
- **Phân nhánh Git (`Git Branching Strategy`)**:
  - Nhánh chính: `main` (Bật Branch Protection, cấm push trực tiếp, bắt buộc Pull Request và duyệt code).
  - Nhánh thành viên: Theo tên hoặc phân mảng của từng thành viên (`quan`, `duc`, `tuan`, v.v.).
- **Ngân sách**: Gói tài trợ sinh viên $200 (Ước tính tiêu thụ tối ưu: $45 - $65).
- **Sản phẩm bàn giao nộp đồ án (Yêu cầu chính thức từ Giảng viên)**:
  1. **File Slide thuyết trình (`.pptx` / Google Slides)**: Nhóm tự thiết kế, trình bày súc tích kiến trúc tổng thể, quy trình triển khai và kết quả các kịch bản thực nghiệm.
  2. **File Docs Báo cáo đồ án (`.docx` / `.pdf` — Độ dài tối thiểu 30 trang)**:
     - Trình bày toàn diện quy trình dự án từ đầu đến cuối (Tuần 1 đến Tuần 7).
     - Đặt vấn đề, phân tích yêu cầu doanh nghiệp và phương án giải quyết bằng AWS Cloud Native & DevSecOps.
     - Thiết kế chi tiết kiến trúc đa tầng (3-Tier Multi-AZ), IaC Terraform, Tầng Tính toán & Container (Docker/ECS), Tầng Dữ liệu & FinOps (Kiểm soát $200), Tầng An ninh DevSecOps (AWS WAF, Secrets Manager, CI/CD).
     - Tổng hợp kết quả thực nghiệm, minh chứng hình ảnh thực tế từ AWS Console và đánh giá bài học kinh nghiệm.
  3. **Video Demo & Trình diễn trực tiếp**:
     - Video quay sẵn kịch bản chạy sản phẩm tại nhà (dùng làm minh chứng nộp kèm và backup khi bảo vệ).
     - Trình diễn trực tiếp (Live Demo) các kịch bản cốt lõi: Self-Healing, WAF Defense, Quản trị FinOps.

---

## 2. PHÂN VAI & PHÂN MẢNG (TRACK ROLES)

| Vai trò | Phân mảng chính | Dịch vụ & Công nghệ phụ trách | Trách nhiệm Demo |
| :--- | :--- | :--- | :--- |
| **Thành viên 1 (Nhóm trưởng)** | **Mạng & IaC** | Terraform, VPC Multi-AZ, Subnets, Routing, Security Groups, ALB, CloudFront, Route 53, Multi-VPC Peering | Trình diễn mã nguồn Terraform 1-click & Sơ đồ kiến trúc mạng đa tầng |
| **Thành viên 2** | **Tính toán & Container** | Docker, ECS Fargate, ECR, EC2 Auto Scaling Group, EFS, Lambda, Elastic Beanstalk / Lightsail | Trình diễn màn **Self-Healing** (Cưỡng bức tắt máy chủ EC2/Task container, ALB tự định tuyến) |
| **Thành viên 3** | **Dữ liệu & FinOps** | RDS MySQL / Aurora Serverless, DynamoDB, S3, S3 Glacier, CloudWatch Metrics/Alarms, CloudTrail, AWS Budgets, Cost Explorer, Redshift Serverless | Trình diễn màn **FinOps & Monitoring** (Phân tích chi phí $200, cảnh báo Budgets, dashboard CloudWatch) |
| **Thành viên 4** | **Bảo mật & DevSecOps** | AWS WAF, AWS Secrets Manager, AWS KMS, Amazon Cognito, GitHub Actions CI/CD Pipeline, Trivy Scanner, Amazon SQS & SNS | Trình diễn màn **WAF Defense** (Bắn payload SQLi, WAF chặn trả về 403 Forbidden) |

---

## 3. BẢNG TIẾN ĐỘ TỔNG QUAN (DASHBOARD)

- [ ] **Thành viên 1 (Mạng & IaC)**: 5/7 hoàn thành (71.4%)
- [ ] **Thành viên 2 (Tính toán & Container)**: 0/7 hoàn thành (0.0%)
- [ ] **Thành viên 3 (Dữ liệu & FinOps)**: 4/7 hoàn thành (57.1%)
- [ ] **Thành viên 4 (Bảo mật & DevSecOps)**: 0/7 hoàn thành (0.0%)

---

## 4. CHI TIẾT 28 ĐẦU VIỆC TRONG 7 TUẦN (TASK BREAKDOWN)

### Tuần 1: Dựng Khung Nền Tảng & Môi Trường Ban Đầu
- [x] **[Thành viên 1] Mạng & IaC**: Viết kịch bản Terraform khởi tạo Production VPC, chia tách Public/Private Subnet đa vùng (`Multi-AZ`), gắn Internet Gateway và NAT Gateway.
  - *Kết quả bàn giao (`Deliverable`)*: Tệp `main.tf`, `vpc.tf`, `subnets.tf` chạy `terraform apply` thành công.
  - *Ghi chú*: Dựng nền móng mạng đầu tiên cho toàn dự án.
- [ ] **[Thành viên 2] Tính toán & Container**: Xây dựng mã nguồn ứng dụng web 3 tầng mẫu (NodeJS/Python), viết `Dockerfile` đóng gói và kiểm thử container cục bộ.
  - *Kết quả bàn giao (`Deliverable`)*: Mã nguồn backend/frontend và Dockerfile chạy mượt trên local.
  - *Ghi chú*: Không cần giao diện phức tạp, tập trung vào API.
- [x] **[Thành viên 3] Dữ liệu & FinOps**: Cấu hình IAM User cho 4 thành viên theo nguyên tắc đặc quyền tối thiểu (`Least Privilege`), thiết lập AWS Budgets cảnh báo $20/$50 gửi email.
  - *Kết quả bàn giao (`Deliverable`)*: 4 tài khoản IAM phân quyền rõ ràng, ảnh chụp AWS Budgets cảnh báo email.
  - *Ghi chú*: Bắt buộc hoàn thành sớm để kiểm soát ngân sách $200.
- [ ] **[Thành viên 4] Bảo mật & DevSecOps**: Khởi tạo kho chứa GitHub repo, thiết lập quy chuẩn Gitflow và tạo AWS Secrets Manager lưu trữ thông tin nhạy cảm ban đầu.
  - *Kết quả bàn giao (`Deliverable`)*: GitHub repository, cấu hình ban đầu trên AWS Secrets Manager.
  - *Ghi chú*: Chuẩn bị môi trường cho đường ống CI/CD.

### Tuần 2: Tầng Lưu Trữ, Dữ Liệu & Máy Chủ Tính Toán
- [x] **[Thành viên 1] Mạng & IaC**: Viết cấu hình Security Group (tường lửa ảo) kiểm soát chặt chẽ inbound/outbound giữa các tầng web, app và database.
  - *Kết quả bàn giao (`Deliverable`)*: File `security_groups.tf` và tài liệu quy tắc mở cổng.
  - *Ghi chú*: Tuân thủ nghiêm ngặt Principle of Least Privilege.
- [ ] **[Thành viên 2] Tính toán & Container**: Triển khai EC2 Auto Scaling Group đặt sau Application Load Balancer (`ALB`), mount ổ đĩa chia sẻ Amazon EFS.
  - *Kết quả bàn giao (`Deliverable`)*: ALB DNS endpoint truy cập được trang web, mount EFS thành công.
  - *Ghi chú*: Kiểm thử co giãn tải (`Scale in/out`) cơ bản.
- [x] **[Thành viên 3] Dữ liệu & FinOps**: Khởi tạo Amazon RDS MySQL / Aurora Serverless trong Private Subnet; tạo S3 Bucket lưu trữ tài nguyên tĩnh.
  - *Kết quả bàn giao (`Deliverable`)*: Endpoint kết nối RDS, S3 Bucket kích hoạt mã hóa SSE-S3.
  - *Ghi chú*: Chọn cấu hình db.t3.micro hoặc 0.5 ACU để tiết kiệm chi phí.
- [ ] **[Thành viên 4] Bảo mật & DevSecOps**: Tích hợp Amazon Cognito User Pool để quản lý chức năng đăng ký, xác thực đăng nhập và cấp phát JWT token.
  - *Kết quả bàn giao (`Deliverable`)*: Cognito User Pool ID, luồng xác thực đăng nhập trả về token thành công.
  - *Ghi chú*: Không cần tự viết code xác thực người dùng thủ công.

### Tuần 3: Chuyển Đổi Container Hóa & Tối Ưu Tải
- [x] **[Thành viên 1] Mạng & IaC**: Cấu hình Amazon Route 53 (phân giải tên miền) và Amazon CloudFront (CDN) tối ưu hóa tốc độ tải trang toàn cầu.
  - *Kết quả bàn giao (`Deliverable`)*: CloudFront distribution domain name hoạt động và chuyển tiếp đúng về ALB/S3.
  - *Ghi chú*: Tối ưu hóa bộ nhớ đệm (`caching`) cho tệp tĩnh.
- [ ] **[Thành viên 2] Tính toán & Container**: Khởi tạo Amazon ECR, đẩy ảnh Docker lên kho lưu trữ và thiết lập ECS Task Definition chạy trên AWS Fargate.
  - *Kết quả bàn giao (`Deliverable`)*: Amazon ECR repository URI, ECS Cluster và Fargate Service active.
  - *Ghi chú*: Chuyển đổi hoàn toàn workload sang kiến trúc container.
- [x] **[Thành viên 3] Dữ liệu & FinOps**: Tạo Amazon DynamoDB lưu trữ dữ liệu phi quan hệ (User Session, Cart); cấu hình S3 Lifecycle chuyển tài liệu cũ sang S3 Glacier sau 30 ngày.
  - *Kết quả bàn giao (`Deliverable`)*: DynamoDB table active, S3 Lifecycle rule hoạt động.
  - *Ghi chú*: Tận dụng gói miễn phí của DynamoDB.
- [ ] **[Thành viên 4] Bảo mật & DevSecOps**: Xây dựng GitHub Actions CI/CD Pipeline tự động: Chạy Unit Test và quét lỗ hổng ảnh Docker bằng công cụ Trivy.
  - *Kết quả bàn giao (`Deliverable`)*: File `.github/workflows/ci.yml` quét bảo mật tự động khi push code.
  - *Ghi chú*: Điểm nhấn thực chiến quan trọng của DevSecOps.

### Tuần 4: Bảo Mật Ứng Dụng & Giám Sát Tập Trung
- [x] **[Thành viên 1] Mạng & IaC**: Triển khai AWS WAF gắn trực tiếp vào ALB: Thiết lập bộ luật chặn SQL Injection, XSS và Rate Limiting (100 req/5 phút).
  - *Kết quả bàn giao (`Deliverable`)*: AWS WAF Web ACL gắn với ALB, trạng thái bảo vệ active.
  - *Ghi chú*: Vũ khí cốt lõi để chuẩn bị demo phòng thủ trước hội đồng.
- [ ] **[Thành viên 2] Tính toán & Container**: Tích hợp ECS Fargate với ALB Target Group, thiết lập Health Check và hoàn thiện kết nối ứng dụng với Database.
  - *Kết quả bàn giao (`Deliverable`)*: Web app chạy mượt mà trên ECS Fargate thông qua tên miền ALB/CloudFront.
  - *Ghi chú*: Đảm bảo tính sẵn sàng cao (`High Availability`) đa AZ.
- [x] **[Thành viên 3] Dữ liệu & FinOps**: Cấu hình Amazon CloudWatch Metrics, Log Groups và Alarms cảnh báo quá tải CPU > 70%; kích hoạt AWS CloudTrail ghi vết API.
  - *Kết quả bàn giao (`Deliverable`)*: CloudWatch Dashboard theo dõi hạ tầng, CloudTrail trail lưu log vào S3.
  - *Ghi chú*: Đảm bảo khả năng quan sát hệ thống (`Observability`).
- [ ] **[Thành viên 4] Bảo mật & DevSecOps**: Cấu hình AWS Secrets Manager và KMS; ứng dụng tự động gọi API lấy mật khẩu DB mà không hardcode trong mã nguồn.
  - *Kết quả bàn giao (`Deliverable`)*: Khóa mã hóa KMS, ứng dụng kết nối DB thông qua credential lấy từ Secrets Manager.
  - *Ghi chú*: Tiêu chuẩn bắt buộc cho bảo mật cấp doanh nghiệp.

### Tuần 5: Kiến Trúc Mở Rộng & Dịch Vụ Nâng Cao
- [x] **[Thành viên 1] Mạng & IaC**: Khởi tạo VPC thứ 2 (Management/DevSecOps VPC) và thiết lập kết nối VPC Peering / Transit Gateway định tuyến an toàn.
  - *Kết quả bàn giao (`Deliverable`)*: Sơ đồ Multi-VPC, bảng Route Table định tuyến thông suốt giữa 2 VPC.
  - *Ghi chú*: Chứng minh năng lực kiến trúc mạng doanh nghiệp cao cấp.
- [ ] **[Thành viên 2] Tính toán & Container**: Thiết lập AWS Lambda xử lý ảnh tải lên S3 và cấu hình Elastic Beanstalk / Lightsail chạy ứng dụng phụ demo.
  - *Kết quả bàn giao (`Deliverable`)*: Lambda function tự động nén ảnh trên S3, môi trường demo staging chạy ổn định.
  - *Ghi chú*: Bao phủ 100% danh mục tính toán trong đề cương.
- [ ] **[Thành viên 3] Dữ liệu & FinOps**: Khởi chạy Amazon Redshift Serverless demo 1–2 giờ, nạp dữ liệu mẫu chạy câu truy vấn phân tích, chụp ảnh minh chứng rồi xóa cụm.
  - *Kết quả bàn giao (`Deliverable`)*: Ảnh chụp truy vấn phân tích dữ liệu trên Redshift và báo cáo chi phí tối ưu.
  - *Ghi chú*: Bắt buộc tắt và xóa ngay để không tiêu hao credit.
- [ ] **[Thành viên 4] Bảo mật & DevSecOps**: Triển khai kiến trúc Event-Driven: Tích hợp Amazon SNS + Amazon SQS để gửi thông báo/email giao dịch bất đồng bộ.
  - *Kết quả bàn giao (`Deliverable`)*: Hàng đợi SQS và chủ đề SNS hoạt động, gửi email thông báo thành công.
  - *Ghi chú*: Kiến trúc hướng sự kiện ghi điểm cộng chuyên môn rất cao.

### Tuần 6: Tối Ưu Hóa & Diễn Tập Kịch Bản Demo Bảo Vệ
- [ ] **[Thành viên 1] Mạng & IaC**: Chuẩn hóa và đóng gói toàn bộ mã nguồn Terraform, hoàn thiện kịch bản 1 lệnh `terraform apply` dựng lại toàn bộ hạ tầng.
  - *Kết quả bàn giao (`Deliverable`)*: Thư mục mã nguồn Terraform hoàn chỉnh kèm tài liệu hướng dẫn triển khai.
  - *Ghi chú*: Chứng minh khả năng tự động hóa hạ tầng hoàn toàn.
- [ ] **[Thành viên 2] Tính toán & Container**: Diễn tập kịch bản demo Self-Healing: Cưỡng bức tắt máy chủ EC2/Container để kiểm tra ALB cân bằng tải và ASG tự sinh máy mới.
  - *Kết quả bàn giao (`Deliverable`)*: Kịch bản và video quay thử màn phục hồi tự động trong dưới 2 phút.
  - *Ghi chú*: Màn demo số 1 hạ gục hội đồng chấm thi.
- [ ] **[Thành viên 3] Dữ liệu & FinOps**: Trực quan hóa chi tiêu thực tế trên AWS Cost Explorer, đối chiếu ngân sách với gói $200, đánh giá AWS Well-Architected Tool.
  - *Kết quả bàn giao (`Deliverable`)*: Bảng báo cáo tài chính đám mây FinOps và file đánh giá 6 trụ cột Well-Architected.
  - *Ghi chú*: Màn demo số 3 thể hiện tư duy tối ưu chi phí.
- [ ] **[Thành viên 4] Bảo mật & DevSecOps**: Diễn tập kịch bản demo WAF Defense: Gửi lệnh curl chứa mã độc SQL Injection và XSS, chứng minh WAF chặn đứng trả về 403 Forbidden.
  - *Kết quả bàn giao (`Deliverable`)*: Lệnh curl thử nghiệm tấn công, ảnh chụp mã 403 và log CloudWatch WAF ghi nhận.
  - *Ghi chú*: Màn demo số 2 thể hiện năng lực bảo mật thực chiến.

### Tuần 7: Báo Cáo Đồ Án, Slide & Video Dự Phòng
- [ ] **[Thành viên 1] Mạng & IaC**: Viết báo cáo đồ án phần Mạng (VPC, Subnets, Routing, Multi-VPC Peering), mã nguồn Terraform và sơ đồ kiến trúc mở rộng.
  - *Kết quả bàn giao (`Deliverable`)*: Bản thảo Word/LaTeX chương Mạng & Tự động hóa hạ tầng.
  - *Ghi chú*: Đính kèm toàn bộ mã nguồn Terraform trong phụ lục.
- [ ] **[Thành viên 2] Tính toán & Container**: Viết báo cáo đồ án phần Máy chủ tính toán, Container (Docker, ECS Fargate), cơ chế High Availability và Self-Healing.
  - *Kết quả bàn giao (`Deliverable`)*: Bản thảo Word/LaTeX chương Tầng Tính toán & Container hóa.
  - *Ghi chú*: Đính kèm hình ảnh kiểm thử tải và cơ chế co giãn.
- [ ] **[Thành viên 3] Dữ liệu & FinOps**: Viết báo cáo đồ án phần Lưu trữ & Dữ liệu (RDS, DynamoDB, S3, Redshift), Hệ thống giám sát CloudWatch và Chiến lược FinOps.
  - *Kết quả bàn giao (`Deliverable`)*: Bản thảo Word/LaTeX chương Dữ liệu, Giám sát & Quản trị tài chính.
  - *Ghi chú*: Đính kèm biểu đồ chi phí thực tế từ Cost Explorer.
- [ ] **[Thành viên 4] Bảo mật & DevSecOps**: Viết báo cáo đồ án phần An ninh bảo mật (WAF, Secrets Manager, KMS, Cognito, CI/CD DevSecOps); làm Slide thuyết trình và Video backup.
  - *Kết quả bàn giao (`Deliverable`)*: Bản thảo Word/LaTeX chương Bảo mật, bộ Slide thuyết trình hoàn chỉnh và Video demo dự phòng.
  - *Ghi chú*: Chuẩn bị kỹ lưỡng để nhóm bảo vệ tự tin tuyệt đối.

---

## 5. KỊCH BẢN DEMO THỰC CHIẾN (LIVE DEMO SCRIPT)
1. **Màn 1: Self-Healing (Tự phục hồi hạ tầng)**
   - Bước 1: Mở web trên trình duyệt đang truy cập bình thường.
   - Bước 2: Vào AWS Console bấm Terminate 1 máy EC2 hoặc stop 1 ECS task.
   - Bước 3: F5 web vẫn sống (do ALB chuyển hướng). Sau 1-2 phút, Auto Scaling Group / ECS tự sinh task mới thay thế.
2. **Màn 2: WAF Defense (Phòng thủ an ninh mạng)**
   - Bước 1: Chạy lệnh `curl -i "http://<alb-endpoint>/search?q=' OR 1=1 --"`
   - Bước 2: Server trả về HTTP Status `403 Forbidden` ngay tức thì.
   - Bước 3: Mở CloudWatch WAF Metrics chỉ cho giảng viên thấy đồ thị request bị Block theo thời gian thực.
3. **Màn 3: FinOps & IaC (Quản trị vận hành chuẩn doanh nghiệp)**
   - Bước 1: Trình chiếu kho GitHub Actions tự động scan mã nguồn và Docker image bằng Trivy.
   - Bước 2: Trình chiếu cây thư mục Terraform triển khai tự động.
   - Bước 3: Mở AWS Cost Explorer & AWS Budgets chứng minh kiểm soát chặt chẽ ngân sách $200.
