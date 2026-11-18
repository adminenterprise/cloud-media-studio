# LỊCH TRÌNH ĐẾM NGƯỢC, KỊCH BẢN VIDEO DEMO & SLIDE BẢO VỆ (THEO VAI CÔNG TY TƯ VẤN CLOUD)

---

## 1. MỐC THỜI GIAN QUAN TRỌNG CẦN NHỚ (TÍNH TỪ HÔM NAY 18/11)

- **Ngày thi bảo vệ chính thức:** **13h30 chiều ngày 02/12/2026**
- **Hạn chót nộp Báo cáo mềm (`.pdf`) + Video Demo** *(trước ngày thi 05 ngày)*: **Muộn nhất ngày 27/11/2026** *(chỉ còn đúng 9 ngày!)*
- **Lộ trình chia việc 9 ngày tới cho 4 thành viên:**
  - **18/11 – 21/11:** Chụp đủ **10 tấm ảnh màn hình thật** theo đúng hướng dẫn trong file `BAO_CAO_DU_AN_CLOUD_MEDIA_STUDIO.md`, dán vào Word/Docs, căn lề trang bìa và xuất sẵn bản nháp `.pdf`.
  - **22/11 – 24/11:** Quay **Video Demo (10–12 phút)** theo đúng kịch bản 4 bước bên dưới và dựng **13 trang Slide**.
  - **25/11 – 26/11:** Cả nhóm xem lại lần cuối, kiểm tra link video mở công khai được không, in **01 bản báo cáo cứng** để sẵn và nộp **bản mềm `.pdf` + Video** đúng hạn **27/11**.
  - **01/12 & Sáng 02/12:** Chạy lại lệnh `node scripts/verify-live-cloud-pipeline.js` (mất 10 giây) để kiểm tra đường truyền AWS mượt 100% trước khi vào phòng thi lúc **13h30 chiều 02/12**.

---

## 2. CÁCH ĐÓNG VAI "CÔNG TY TƯ VẤN & TRIỂN KHAI CLOUD" ĐỂ ĂN ĐIỂM SÁNG TẠO (8.5 – 10)

Giảng viên đã gợi ý rất rõ luồng tư duy chấm điểm:
> **`Yêu cầu ban đầu của KH` ➔ `Phân tích, thảo luận chốt kế hoạch (Yêu cầu <-> Giải pháp)` ➔ `Thiết kế` ➔ `Triển khai & Test (UAT)` ➔ `Bàn giao, chuyển giao công nghệ`**

Đa số các nhóm khác sẽ vẫn trình bày kiểu sinh viên trả bài (*"Nhóm em xin báo cáo đề tài..."*). Nhóm bạn chỉ cần giữ đúng vai xuyên suốt trong cả Báo cáo, Video và buổi thuyết trình chiều 02/12:
- **Vai của nhóm bạn:** Đội ngũ 4 Kỹ sư của **Đơn vị Tư vấn & Triển khai Đám mây (NovaCloud Consulting)**.
- **Khách hàng của dự án:** **Lumina Creative Agency** — công ty sản xuất ảnh quảng cáo 4K và video cho 30 nhãn hàng, đang khổ sở vì máy chủ vật lý ở văn phòng hay treo lúc cao điểm, tải ảnh chậm và tốn tiền mua ổ cứng lưu ảnh chiến dịch cũ.
- **Điểm đắt giá nhất khi tư vấn:** Khách hàng ban đầu đòi *"thuê máy chủ thật to bật 24/7 và mở kho S3 công khai cho tiện trong gói 200 USD"*. Đội tư vấn của bạn đã phân tích bác bỏ cách làm rủi ro/tốn tiền đó, thuyết phục khách hàng chốt phương án **CloudFront OAC + S3 Presigned URL + AWS Lambda ARM64 (`sharp`) + S3 Glacier IR**, giúp khách hàng giữ chi phí duy trì lúc rảnh bằng **0 USD** mà bảo mật tuyệt đối!

---

## 3. KỊCH BẢN QUAY VIDEO DEMO 4 GIAI ĐOẠN (THỜI LƯỢNG: 10 – 12 PHÚT)

> Đảm bảo có đủ cả **Cài đặt ➔ Cấu hình ➔ Kiểm thử nghiệm thu ➔ Bàn giao vận hành** đúng yêu cầu đề bài.

### Giai đoạn 1: Tóm tắt bài toán Khách hàng & CÀI ĐẶT hạ tầng bằng Terraform + CI/CD (00:00 – 03:30)
1. **Mở đầu (45 giây):** Chiếu sơ đồ kiến trúc đã chốt với khách hàng Lumina Creative Agency. Nêu rõ mục tiêu: tải ảnh trực tiếp lên S3 không lộ khóa, tự nén WebP giảm >80% dung lượng, phát qua CDN dưới 50ms và chuyển kho lạnh Glacier giảm 84% chi phí lưu trữ.
2. **Quay màn hình Cài đặt bằng Terraform IaC (00:45 – 02:15):**
   - Mở VS Code chiếu cấu trúc thư mục `terraform/` (mạng Dual-VPC, CloudFront, S3 CORS, 2 hàm Lambda ARM64) và chỉ vào các công tắc tiết kiệm tiền trong `terraform.tfvars`.
   - Mở Terminal chạy trực tiếp:
     ```powershell
     terraform -chdir=terraform fmt -check
     terraform -chdir=terraform validate
     ```
3. **Quay màn hình Cài đặt đường ống GitHub Actions OIDC (02:15 – 03:30):**
   - Mở tab **GitHub -> Actions**, bấm vào lần chạy tích xanh gần nhất của `deploy-frontend.yml` và `ci.yml`.
   - Chỉ rõ bước xác thực **AWS OIDC** (không lưu khóa tĩnh của khách hàng trên GitHub), bước quét lỗ hổng **Aqua Trivy** và bước tự động xóa cache CloudFront (`Invalidation`).

### Giai đoạn 2: Kiểm chứng CẤU HÌNH thực tế trên AWS Console Singapore (03:30 – 06:30)
Mở trình duyệt **AWS Console (`ap-southeast-1`)** lướt qua 4 cấu hình đã dựng cho khách hàng:
1. **IAM Console:** Chỉ 4 nhóm quyền theo vai trò kỹ sư (`Network`, `Compute`, `Data-FinOps`, `Security`) và nhà cung cấp định danh OIDC GitHub.
2. **VPC Console:** Mở *Resource map* của Production VPC (`10.0.0.0/16` - 6 Subnets đa vùng AZ) và kết nối *VPC Peering* `Active` sang Management VPC (`10.1.0.0/16`).
3. **S3 Console (`cloud-media-studio-assets-586643076560`):**
   - Tab *Permissions*: Khóa Public Access (chỉ cho CloudFront đọc qua OAC) + Cấu hình **CORS** cho phép trình duyệt khách hàng `PUT` qua Presigned URL.
   - Tab *Properties*: Bộ lọc sự kiện `uploads/` kích hoạt hàm xử lý ảnh (chặn vòng lặp vô hạn).
4. **AWS Lambda Console:** Chỉ rõ 2 hàm chạy trên chip `arm64` Graviton2 là `cloud-media-studio-api` (cấp vé S3 Presigned URL) và `cloud-media-studio-image-processor` (tích hợp thư viện nén ảnh C++ `sharp`).

### Giai đoạn 3: KIỂM THỬ NGHIỆM THU (UAT) trực tiếp trên CloudFront (06:30 – 10:30)
1. **Nghiệm thu tải ảnh trực tiếp qua S3 Presigned URL & Nén WebP thật:**
   - Mở cửa sổ trình duyệt truy cập **`https://d10b9bys5mn60c.cloudfront.net`** (chứng minh chạy 100% trên đám mây, không cần bật máy chủ cục bộ).
   - Vào **Upload Media**, chọn 1 tệp ảnh nặng vài MB trên máy tính -> Bấm nút xanh **`⚡ Kích Hoạt Lambda Thật Trên AWS S3`**.
   - Đợi ~2 giây, chỉ rõ thông số hiện ra trên thẻ kết quả: Dung lượng gốc giảm hơn 90% sang chuẩn `.webp`, bấm mở trực tiếp link **WebP chính** và **3 bản Thumbnail (`320w`, `768w`, `1200w`)** trên tab mới.
   - Sang tab **AWS S3 Console**, bấm *Refresh* vào 3 thư mục `uploads/`, `processed/` và `thumbnails/` để đối chứng các tệp `.webp` thật vừa được sinh ra trên đám mây; mở **CloudWatch Logs** xem dòng nhật ký thực thi.
2. **Nghiệm thu đồng bộ S3 khi F5 & Chuyển kho lạnh S3 Glacier thật:**
   - Tại trang CloudFront, vào **Media Library**, bấm **`F5`** -> Dữ liệu vẫn giữ nguyên đầu danh sách nhờ đồng bộ trực tiếp với S3.
   - Bấm vào bức ảnh vừa tải -> Bấm nút **`Move to Glacier (FinOps)`** -> Sang **AWS S3 Console** bấm *Refresh*, chỉ rõ cột `Storage class` đã chuyển thật từ `Standard` sang **`Glacier Instant Retrieval`**!
3. **Nghiệm thu bảo mật chống SQL Injection (`403`) & Rate Limit (`429`):**
   - Mở Terminal chạy bộ kiểm thử nghiệm thu tự động:
     ```powershell
     node scripts/verify-live-cloud-pipeline.js
     ```
     Và chạy thử nghiệm tấn công SQLi:
     ```powershell
     curl.exe -i "https://jtkvl7zyutkt34p3m5g3ui76ge0mehbp.lambda-url.ap-southeast-1.on.aws/api/search?q=%27%20OR%201=1%20--"
     ```
     Chỉ rõ phản hồi chặn đứng **`HTTP 403 Forbidden`** và kết quả chặn vượt ngưỡng tải **`HTTP 429`** từ `node tests/run-rate-limit-test.js`.

### Giai đoạn 4: BÀN GIAO & CHUYỂN GIAO CÔNG NGHỆ cho IT Khách hàng (10:30 – 11:30)
- Chiếu phần **Sổ tay vận hành (Runbook)** ở Phần 6 của báo cáo và bảng **AWS Budgets** khóa trần 200 USD:
  - Chỉ cho khách hàng thấy sau khi bàn giao, IT nội bộ cập nhật giao diện chỉ bằng 1 lệnh `git push`, kiểm tra sức khỏe toàn hệ thống bằng 1 lệnh `node scripts/verify-live-cloud-pipeline.js`, và bật/tắt cụm chịu tải mùa chiến dịch chỉ bằng 1 biến trong `terraform.tfvars`.

---

## 4. BỐ CỤC 13 TRANG SLIDE THUYẾT TRÌNH CHIỀU 02/12 (13H30)

| Slide | Tiêu đề Slide | Người trình bày | Nội dung chính trên Slide |
| :---: | :--- | :---: | :--- |
| **1** | Hồ sơ Tư vấn & Bàn giao Giải pháp Cloud Media Studio | TV1 | Tên đơn vị tư vấn, khách hàng giả định **Lumina Creative Agency**, danh sách 4 kỹ sư phụ trách & **Mã QR** trỏ thẳng vào `https://d10b9bys5mn60c.cloudfront.net`. |
| **2** | Hiện trạng Khách hàng & 3 Nỗi đau vận hành (Đặt vấn đề) | TV1 | Máy chủ vật lý tại văn phòng: (1) Ảnh 4K nặng gây chậm web đối tác; (2) Treo CPU lúc chiến dịch nhưng bỏ không ban đêm; (3) Ảnh cũ nhiều năm làm đầy ổ cứng SSD. |
| **3** | Thảo luận & Tư vấn điều chỉnh yêu cầu cùng Khách hàng | TV1 | So sánh yêu cầu thô ban đầu của KH *(đòi thuê server to bật 24/7 + mở S3 công khai)* với phương án tư vấn tối ưu *(Serverless ARM64 + Presigned URL + Glacier trong trần 200 USD)*. |
| **4** | **Ma trận chốt kế hoạch: Yêu cầu KH <-> Giải pháp Đề xuất** | TV1 | Bảng ánh xạ `YC-01` đến `YC-07`, tách rõ cột **Dịch vụ cơ bản học trên lớp** và cột **Dịch vụ nâng cao mở rộng** *(ăn thẳng vào tiêu chí Xuất sắc 8.5–10)*. |
| **5** | Thiết kế Mạng Doanh nghiệp: Dual-VPC Multi-AZ & CloudFront OAC | TV1 | Sơ đồ mạng Production VPC (`10.0.0.0/16` - 6 Subnets) nối Peering sang Management VPC (`10.1.0.0/16`); khóa kín S3 bằng chữ ký OAC SigV4. |
| **6** | Thiết kế Luồng Tải & Xử lý 100% Cloud-Native Serverless | TV2 | Sơ đồ luồng 5 bước: Xin vé `S3 Presigned PUT URL` (5 phút) ➔ Đẩy thẳng lên S3 `uploads/` ➔ S3 Event gọi Lambda `sharp` ARM64 ➔ Xuất `.webp` + 3 Thumbnails thật. |
| **7** | Thiết kế DevSecOps CI/CD không khóa tĩnh & Terraform IaC | TV4 | Quy trình GitHub Actions mượn quyền tạm thời qua **AWS OIDC**, quét lỗ hổng **Aqua Trivy** và tự xóa cache CloudFront sau 45 giây. |
| **8** | Thiết kế FinOps: Vòng đời S3 Glacier & Công tắc chi phí | TV3 | Bài toán kinh tế cho KH: Giảm 84% phí lưu trữ sau 30 ngày (`$0.025` xuống `$0.004/GB`), công tắc Terraform giữ chi phí cố định ngày thường bằng `$0.00`. |
| **9** | Nhật ký Triển khai & Xử lý sự cố kỹ thuật thực tế | TV2 | 3 kinh nghiệm thực chiến: Xử lý cache 24h của CloudFront; khóa `filter_prefix = "uploads/"` chống lặp Lambda vô hạn; đóng gói thư viện C++ `libvips` trên Linux ARM64. |
| **10** | Kết quả Nghiệm thu UAT 1: Tốc độ & Nén ảnh WebP thật trên S3 | TV2 | Ảnh chụp S3 Console thật: Ảnh PNG **3,04 MB** nén còn **74,4 KB** (**giảm 97,6%**) + 3 cỡ Thumbnail (`5,8 KB`, `30 KB`, `55,6 KB`), phản hồi CDN ~30ms. |
| **11** | Kết quả Nghiệm thu UAT 2: An ninh (`403`/`429`) & Ngân sách | TV4 & TV3 | Minh chứng chặn tấn công SQLi `' OR 1=1 --`, chặn spam tải quá ngưỡng và bảng theo dõi hóa đơn AWS Budgets thực tế dưới trần 200 USD. |
| **12** | Bàn giao Hệ thống & Chuyển giao Sổ tay Vận hành (Runbook) | TV3 | Bàn giao Endpoints, mã Terraform, quyền IAM MFA và 4 quy trình SOP để đội IT khách hàng tự cập nhật web, bật/tắt tải mùa sale và giám sát log. |
| **13** | Lộ trình Giai đoạn 2 & Mời Hội đồng Trải nghiệm Trực tiếp | TV1 | Đề xuất nâng cấp Multipart Video & AWS MediaConvert HLS; mời giảng viên quét mã QR lấy điện thoại tải thử 1 bức ảnh bất kỳ lên S3 ngay tại phòng thi! |
