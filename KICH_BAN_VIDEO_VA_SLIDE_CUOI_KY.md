# KỊCH BẢN QUAY VIDEO DEMO & DÀN Ý SLIDE BẢO VỆ CUỐI KỲ
**Dự án:** Cloud Media Studio trên AWS Public Cloud (`ap-southeast-1`)  
**Hạn nộp lưu ý:** Nộp bản mềm Báo cáo (`.pdf`) + Video Demo trước ngày báo cáo **05 ngày**.

---

## PHẦN A. KỊCH BẢN QUAY VIDEO DEMO CHI TIẾT (THỜI LƯỢNG CHUẨN: 10 – 12 PHÚT)

> **Lưu ý quan trọng để ăn trọn điểm Video (nằm trong trọng số 30%):**
> Đề bài ghi rõ video phải có đủ **3 giai đoạn: Cài đặt -> Cấu hình -> Test hệ thống**. Tuyệt đối không chỉ mở sẵn trang web lên bấm vài nút rồi kết thúc. Hãy mở sẵn các tab trình duyệt AWS Console (chọn vùng **Singapore `ap-southeast-1`**), GitHub Actions, VS Code Terminal và quay nối tiếp theo đúng 3 hồi dưới đây.

### Hồi 1: Giới thiệu kiến trúc & Quá trình CÀI ĐẶT hạ tầng tự động (Phút 00:00 – 03:30)
- **00:00 – 00:45 (Mở đầu):**
  - Hiện slide sơ đồ kiến trúc tổng thể trong 30 giây, giới thiệu ngắn gọn: *"Nhóm em triển khai hệ thống Cloud Media Studio trên AWS vùng Singapore nhằm giải quyết bài toán tự động nén ảnh WebP, phân phối CDN và tối ưu chi phí lưu trữ lạnh S3 Glacier."*
- **00:45 – 02:15 (Quay cảnh Cài đặt hạ tầng bằng Terraform IaC):**
  - Mở VS Code cho thấy thư mục `terraform/` gồm các file chia tách rõ ràng (`vpc.tf`, `subnets.tf`, `security_groups.tf`, `cloudfront.tf`, `lambda.tf`, `waf.tf`, `ecs_fargate.tf`).
  - Mở Terminal gõ trực tiếp 3 lệnh để chứng minh quá trình cài đặt bằng mã nguồn:
    ```powershell
    terraform -chdir=terraform fmt -check
    terraform -chdir=terraform validate
    ```
  - Giải thích ngắn: *"Toàn bộ mạng Dual-VPC, 6 Subnets trên 2 Availability Zones, S3, CloudFront và 2 hàm Lambda ARM64 đều được khởi tạo tự động qua Terraform thay vì bấm tay rời rạc."*
- **02:15 – 03:30 (Quay cảnh Cài đặt & Đẩy code tự động qua GitHub Actions OIDC):**
  - Mở file `.github/workflows/deploy-frontend.yml` và `ci.yml`, chỉ vào dòng `role-to-assume: arn:aws:iam::586643076560:role/github-action` (nhấn mạnh không dùng khóa tĩnh `Access Key`).
  - Mở tab **GitHub -> Actions**, bấm vào phiên chạy dấu tích xanh gần nhất để thấy quá trình cài đặt tự động: `npm run build` -> Xác thực AWS OIDC -> Đồng bộ S3 (có cờ bảo vệ `uploads/`, `processed/`, `thumbnails/`) -> Xóa cache CloudFront (`Invalidation`).

### Hồi 2: Kiểm chứng CẤU HÌNH thực tế trên AWS Console (Phút 03:30 – 06:30)
Chuyển sang trình duyệt mở **AWS Management Console (Region: Singapore)**, lướt qua 4 cấu hình cốt lõi:
1. **Cấu hình IAM & Phân quyền (03:30 – 04:10):** Mở *IAM -> User groups* chỉ 4 nhóm quyền theo nguyên tắc đặc quyền tối thiểu và mục *Identity providers* kết nối OIDC với GitHub.
2. **Cấu hình Mạng Dual-VPC (04:10 – 04:50):** Mở *VPC -> Your VPCs -> Production VPC (`10.0.0.0/16`) -> Tab Resource map* chỉ rõ 6 Subnets (2 Public, 2 Private App, 2 Private DB) và tab *Peering connections* nối sang Management VPC (`10.1.0.0/16`) đang ở trạng thái `Active`.
3. **Cấu hình Amazon S3 & CloudFront OAC (04:50 – 05:40):**
   - Mở *S3 -> `cloud-media-studio-assets-586643076560` -> Tab Permissions*: Chỉ cấu hình khóa Public Access (chỉ cho CloudFront đọc qua OAC) và kéo xuống chỉ cấu hình **CORS** cho phép tên miền CloudFront thực hiện lệnh `PUT` qua Presigned URL.
   - Chuyển sang tab *Properties -> Event notifications*: Chỉ rõ bộ lọc sự kiện `uploads/` kích hoạt hàm Lambda xử lý ảnh.
4. **Cấu hình 2 hàm AWS Lambda chạy chip ARM64 Graviton2 (05:40 – 06:30):**
   - Mở *AWS Lambda -> Functions*: Chỉ rõ 2 hàm đang hoạt động là `cloud-media-studio-api` (gắn HTTPS Function URL cấp vé S3 Presigned URL) và `cloud-media-studio-image-processor` (đóng gói thư viện C++ `sharp` chạy trên kiến trúc `arm64`).

### Hồi 3: TEST HỆ THỐNG thực nghiệm từ đầu đến cuối (Phút 06:30 – 11:30)
Đây là phần ăn điểm trực tiếp cao nhất, chứng minh hệ thống chạy **100% trên đám mây không cần bật localhost**:

1. **Test 1 - Upload ảnh thật trực tiếp từ CloudFront lên S3 & Nén WebP thật (06:30 – 08:30):**
   - Mở trực tiếp trang công khai: **`https://d10b9bys5mn60c.cloudfront.net`** (có thể mở cửa sổ ẩn danh Incognito để chứng minh độc lập hoàn toàn với máy cá nhân).
   - Đăng nhập nhanh -> Vào mục **Upload Media** (chỉ huy hiệu xanh lá `AWS Serverless Connected`).
   - Chọn 1 tấm ảnh `.png` hoặc `.jpg` nặng vài MB trên máy tính -> Bấm nút xanh **`⚡ Kích Hoạt Lambda Thật Trên AWS S3`**.
   - Chỉ vào thẻ kết quả hiện ra sau ~3 giây: Dung lượng ảnh gốc (ví dụ `3,04 MB`) đã được Lambda `sharp` nén thật xuống còn vài chục KB (giảm hơn `90%`), bấm mở trực tiếp các link **WebP chính**, **Mobile 320w**, **Tablet 768w**, **Desktop 1200w** ngay trên trình duyệt!
   - Sang tab **AWS S3 Console**, bấm *Refresh* vào 3 thư mục `uploads/`, `processed/` và `thumbnails/` để thầy thấy tận mắt các file `.webp` thật vừa sinh ra trên đám mây; mở **CloudWatch Logs** thấy dòng log `[Success]` ghi nhận tỷ lệ nén.
2. **Test 2 - Kiểm tra đồng bộ S3 khi F5 & Chuyển kho lạnh S3 Glacier thật (08:30 – 09:45):**
   - Quay lại trang `https://d10b9bys5mn60c.cloudfront.net`, vào **Media Library**, bấm **`F5` (Reload)** -> Ảnh vừa tải vẫn nằm đầu danh sách vì đọc trực tiếp từ S3 thật.
   - Bấm vào bức ảnh vừa tải -> Mở bảng thông số -> Bấm nút xanh **`Move to Glacier (FinOps)`**.
   - Sang lại tab **AWS S3 Console -> `uploads/`**, bấm *Refresh*: Chỉ vào cột **`Storage class`** đã đổi thật từ `Standard` sang **`Glacier Instant Retrieval`** (giảm 84% chi phí lưu trữ)!
3. **Test 3 - Kiểm thử bảo mật chống SQL Injection & Chống Spam tải (09:45 – 11:30):**
   - Mở Terminal chạy lệnh kiểm thử toàn trình tự động:
     ```powershell
     node scripts/verify-live-cloud-pipeline.js
     ```
   - Hoặc chạy lệnh kiểm thử tấn công SQLi trực tiếp vào cổng Cloud API:
     ```powershell
     curl.exe -i "https://jtkvl7zyutkt34p3m5g3ui76ge0mehbp.lambda-url.ap-southeast-1.on.aws/api/search?q=%27%20OR%201=1%20--"
     ```
     Chỉ rõ kết quả trả về **`HTTP/1.1 403 Forbidden`** (`WAF_SQLI_XSS_BLOCKED`).
   - Chạy tiếp bài test giới hạn tốc độ (`node tests/run-rate-limit-test.js`) để thấy khi bắn quá ngưỡng 100 request/phút, hệ thống trả về **`429 Too Many Requests`**.

---

## PHẦN B. DÀN Ý CHI TIẾT 12 SLIDE THUYẾT TRÌNH (BÁM SÁT HỆ SỐ ĐIỂM)

> **Nguyên tắc thiết kế Slide:** Ít chữ, nhiều sơ đồ và ảnh chụp đối chứng thật từ AWS Console của nhóm. Tỷ lệ thời lượng trình bày bám đúng barem chấm: **60% thời gian tập trung nói sâu Bài toán + Giải pháp kiến trúc mở rộng**.

| Trang | Tiêu đề Slide | Người nói | Nội dung cốt lõi cần đưa lên Slide |
| :---: | :--- | :---: | :--- |
| **Slide 1** | Trang bìa: Đề tài & Nhóm thực hiện | TV1 | Tên đề tài **Cloud Media Studio trên AWS**, danh sách 4 thành viên kèm vai trò IAM, link demo sống `d10b9bys5mn60c.cloudfront.net` (kèm mã QR để thầy quét thử ngay bằng điện thoại dưới hội đồng!). |
| **Slide 2** | Đặt vấn đề: 3 nút thắt thực tế | TV1 | (1) Ảnh gốc 4K nặng gây chậm web; (2) Dựng server bật 24/7 chỉ để chờ nén ảnh gây lãng phí CPU; (3) Ảnh cũ sau chiến dịch >30 ngày để trên ổ đĩa chuẩn làm phình hóa đơn lưu trữ. |
| **Slide 3** | Mô tả bài toán & Yêu cầu đặt ra | TV1 | Mục tiêu chức năng (Tải lên -> Tự nén WebP + 3 cỡ Thumbnail -> Phát qua CDN -> Chuyển kho lạnh) & Phi chức năng (Đa vùng AZ Singapore, không lộ AWS Key, gói gọn trong 200 USD). |
| **Slide 4** | **Bảng ánh xạ Dịch vụ Cơ bản vs Dịch vụ Mở rộng (Slide ăn điểm 8.5–10)** | TV1 | Bảng 2 cột đối chiếu rõ: Dịch vụ học trên lớp (VPC, EC2, S3, IAM, RDS) **VÀ** Các dịch vụ nâng cao nhóm tự tích hợp thêm (**VPC Peering, CloudFront OAC, Lambda ARM64 + Function URL, S3 Presigned URL, Glacier IR, WAFv2, GitHub OIDC + Trivy, Terraform**). |
| **Slide 5** | Giải pháp Mạng: Dual-VPC Multi-AZ & CloudFront OAC | TV1 | Sơ đồ kiến trúc Production VPC (`10.0.0.0/16` - 6 Subnets) nối Peering sang Management VPC (`10.1.0.0/16`). Giải thích vì sao khóa S3 bằng chữ ký OAC chỉ cho CloudFront đi vào. |
| **Slide 6** | Giải pháp Xử lý: Luồng 100% Cloud-Native Presigned URL & Lambda `sharp` | TV2 | Sơ đồ 5 bước: Trình duyệt xin vé SigV4 Presigned URL -> Bắn thẳng ảnh lên S3 `uploads/` -> S3 Event đánh thức Lambda ARM64 (`sharp`) -> Nén ra `.webp` thật + 3 Thumbnails (`320w, 768w, 1200w`) trong 2 giây. |
| **Slide 7** | Giải pháp Hạ tầng & DevSecOps CI/CD (Zero Secret Keys) | TV4 | Luồng GitHub Actions: Quét lỗ hổng container bằng **Aqua Trivy** -> Xác thực **AWS OIDC** (tuyệt đối không lưu Access Key tĩnh) -> Tự động đẩy S3 & xóa cache CloudFront. |
| **Slide 8** | Giải pháp Dữ liệu & Tối ưu chi phí FinOps ($200 Credit) | TV3 | So sánh giá S3 Standard (`$0.025/GB`) vs S3 Glacier IR (`$0.004/GB` - giảm 84%). Chiến thuật công tắc Terraform (`enable_nat_gateway`, `enable_alb`) giúp duy trì hệ thống tốn xấp xỉ `$0.00` lúc nghỉ. |
| **Slide 9** | Quá trình cài đặt & Kinh nghiệm gỡ lỗi thực chiến | TV2 | Nêu 3 kinh nghiệm thật khi làm bài: (1) Xử lý cache 24h của CloudFront bằng Invalidation; (2) Khóa `filter_prefix = "uploads/"` chống vòng lặp Lambda vô hạn; (3) Gỡ lỗi thư viện `libvips` trên Linux ARM64. |
| **Slide 10** | Kết quả thực nghiệm 1: Hiệu năng nén WebP & Phân phối CDN | TV2 | Ảnh chụp S3 Console thật: Ảnh PNG gốc **3,04 MB** nén xuống còn **74,4 KB** (giảm **97,6%**) + 3 bản Thumbnail (`5,8 KB`, `30 KB`, `55,6 KB`), tốc độ tải qua CloudFront ~30ms. |
| **Slide 11** | Kết quả thực nghiệm 2: Phòng thủ SQLi, Rate Limit & Hóa đơn AWS | TV4 & TV3 | Ảnh chụp kết quả chặn tấn công `' OR 1=1 --` (`HTTP 403`), kết quả bắn tải tự động chặn vượt ngưỡng (`HTTP 429`) và ảnh chụp bảng theo dõi ngân sách AWS Budgets thực tế. |
| **Slide 12** | Kết luận, Demo trực tiếp & Hướng phát triển | TV1 | Tóm tắt giá trị đạt được, mời thầy quét QR vào thẳng `https://d10b9bys5mn60c.cloudfront.net` tải thử 1 tấm ảnh từ điện thoại của thầy lên S3 ngay tại lớp! |

---

## PHẦN C. BỘ CÂU HỎI PHẢN BIỆN HỘI ĐỒNG HAY HỎI NHẤT & CÁCH TRẢ LỜI ĂN ĐIỂM TUYỆT ĐỐI

1. **Hội đồng hỏi:** *"Tại sao nhóm không gửi thẳng file ảnh qua hàm Lambda API rồi lưu vào S3 luôn, mà lại phải xin S3 Presigned URL rồi mới từ trình duyệt PUT lên S3?"*
   - **Cách trả lời:** *"Thưa thầy, AWS Lambda có giới hạn kích thước gói tin đầu vào tối đa (payload limit) là **6 MB**. Nếu gửi file qua Lambda, người dùng tải ảnh 4K nặng 10 MB hay video 100 MB sẽ bị lỗi ngay. Dùng **S3 Presigned PUT URL** vừa không lộ khóa AWS ra ngoài trình duyệt (vì URL có chữ ký số tự hết hạn sau 5 phút), vừa cho phép trình duyệt đẩy thẳng file nặng hàng GB lên S3 mà không làm nghẽn băng thông Backend ạ."*

2. **Hội đồng hỏi:** *"Hàm Lambda đọc file từ S3 Bucket rồi lại ghi file `.webp` vào chính S3 Bucket đó, các em làm thế nào để nó không tự kích hoạt lại chính nó thành vòng lặp vô hạn làm cháy túi tiền AWS?"*
   - **Cách trả lời:** *"Nhóm em khóa hai lớp bảo vệ kép ạ: Thứ nhất, ở cấu hình S3 Event Notification trong Terraform và trên AWS, nhóm đặt bộ lọc `filter_prefix = "uploads/"` và loại trừ sự kiện `Copy`, nên khi Lambda ghi file kết quả sang thư mục `processed/` và `thumbnails/` thì S3 sẽ không phát sự kiện nữa. Thứ hai, ngay đầu code của hàm Lambda cũng có câu lệnh kiểm tra nếu đường dẫn không bắt đầu bằng `uploads/` thì thoát ngay lập tức."*

3. **Hội đồng hỏi:** *"Tại sao trong code Terraform nhóm lại để biến tắt mở cho NAT Gateway và ALB?"*
   - **Cách trả lời:** *"Đó là chủ đích quản trị chi phí FinOps của nhóm trên gói tài trợ sinh viên ạ. NAT Gateway và ALB tính phí duy trì cố định theo giờ khoảng 54 USD/tháng dù không có người dùng. Nhóm viết mã hóa bằng Terraform để khi cần chạy cụm container ECS Fargate chịu tải lớn thì bật lên bằng 1 lệnh `terraform apply`, còn trong vận hành thường nhật luồng Serverless (CloudFront + S3 Presigned URL + 2 hàm Lambda ARM64) hoạt động 24/7 hoàn toàn nằm trong ngưỡng miễn phí mà vẫn đáp ứng 100% tính năng thực tế."*
