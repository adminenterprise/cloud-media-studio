# DANH SÁCH 18 ẢNH MINH CHỨNG TINH GỌN CHO BÁO CÁO 30+ TRANG

> **Bố cục chuẩn cân đối:** 18 ảnh chụp màn hình đắt giá (mỗi ảnh cao ~1/3 trang Word, chiều rộng 15–16 cm) xen kẽ với nội dung phân tích, 7 bảng biểu, 2 sơ đồ kiến trúc và các khối mã nguồn có sẵn trong `BAO_CAO_DU_AN_CLOUD_MEDIA_STUDIO.md` ➔ Xuất ra Word/PDF đạt **30 – 33 trang** rất thoáng đẹp, không bị cảm giác nhồi ảnh.

---

### Nhóm 1: Quy trình làm việc, Tiến hóa kiến trúc & Phân quyền (3 ảnh — Phần 1 & 2)
1. **Ảnh #01:** Cây thư mục dự án gọn sạch trên VS Code (bung sẵn `.github/workflows/`, `backend/lambda/`, `finops/terraform/`, `frontend/`, `scripts/`, `terraform/`, `tests/`).
2. **Ảnh #02:** Terminal VS Code chạy `git log --oneline --graph --decorate -n 20` (hoặc tab *GitHub -> Pull requests -> Closed* hiển thị PR `#23`, `#24`, `#25` và danh sách nhánh `main`, `mquan`, `thehung`, `doduc`, `ducdien`).
3. **Ảnh #03:** *AWS Console -> IAM -> Identity providers* (`token.actions.githubusercontent.com`) / Role `github-action` tab *Trust relationships* (hoặc *IAM -> User groups*).

### Nhóm 2: Thiết kế Hạ tầng Mạng, S3 & CloudFront trên AWS Singapore (5 ảnh — Phần 3)
4. **Ảnh #04:** *AWS VPC -> Your VPCs -> Production VPC (`10.0.0.0/16`) -> Tab Resource map* (thấy rõ 6 Subnets Multi-AZ, Route Tables và Internet Gateway).
5. **Ảnh #05:** *AWS VPC -> Peering connections* hiển thị kết nối `pcx-05d1fb108616399d3` ở trạng thái **`Active`** giữa `10.0.0.0/16` và `10.1.0.0/16`.
6. **Ảnh #06:** *AWS VPC -> Security Groups -> `cloud-media-studio-db-sg`* tab *Inbound rules* chỉ mở cổng `3306` từ mã `app-sg` (`sg-04e15c5b51f42038f`).
7. **Ảnh #07:** *AWS S3 -> `cloud-media-studio-assets-586643076560` -> Tab Permissions* (thấy *Block all public access: On* và khung *CORS* cho phép `PUT` từ miền CloudFront).
8. **Ảnh #08:** *AWS CloudFront -> Distributions -> `E23QIJLQ2A8EEN`* tab *General* (`d10b9bys5mn60c.cloudfront.net`) và tab *Origins* gắn OAC.

### Nhóm 3: Cài đặt, CI/CD & Nhật ký Gỡ Lỗi Thực Chiến (5 ảnh — Phần 4)
9. **Ảnh #09:** Terminal VS Code chạy `terraform -chdir=terraform validate` (`Success! The configuration is valid.`) và `terraform -chdir=terraform plan "-var-file=terraform.tfvars.example" -lock=false`.
10. **Ảnh #10:** *AWS Lambda -> Functions* hiển thị cả 2 hàm `cloud-media-studio-api` và `cloud-media-studio-image-processor` (`nodejs22.x / arm64`) hoặc tab *Triggers* có `Prefix: uploads/`.
11. **Ảnh #11 *(Ăn điểm chân thực)*:** Tab *GitHub -> Actions* có lần chạy báo dấu X đỏ (`EBADPLATFORM`) và ngay phía trên là lần chạy dấu tích xanh sau commit sửa lỗi `dcf36fa`.
12. **Ảnh #12:** Chi tiết phiên chạy tích xanh của workflow `Deploy Frontend to CloudFront & S3` trên GitHub Actions (mở rộng bước OIDC, S3 Sync và CloudFront Invalidation).
13. **Ảnh #13:** Bước quét lỗ hổng *Trivy scan backend image* trong workflow `CI` trên GitHub Actions (hoặc màn hình *Amazon ECR -> `cloud-media-studio-backend`* & *ECS Cluster*).

### Nhóm 4: Kết quả Kiểm thử Nghiệm thu UAT & FinOps (5 ảnh — Phần 5 & 6)
14. **Ảnh #14:** Mở `https://d10b9bys5mn60c.cloudfront.net` -> Tab *Upload Media*, chụp màn hình ngay sau khi tải 1 ảnh thật lên S3 (hiện huy hiệu xanh `AWS Serverless Connected`, 5 bước tích xanh và dung lượng nén WebP giảm >90% + 3 link Thumbnail).
15. **Ảnh #15:** *AWS S3 Console -> `cloud-media-studio-assets-586643076560`* đối chứng 3 thư mục `uploads/` (có dòng file đã bấm *Move to Glacier* hiển thị cột `Storage class` là **`Glacier Instant Retrieval`**), `processed/` (ảnh `.webp`) và `thumbnails/`.
16. **Ảnh #16:** *AWS CloudWatch -> Log groups -> `/aws/lambda/cloud-media-studio-image-processor`* chụp dòng log `[Success] Đã ghi thật lên S3: processed/...webp + 3 Thumbnails!`.
17. **Ảnh #17:** Terminal chạy `node scripts/verify-live-cloud-pipeline.js` PASS 6/6 bước (có chốt chặn SQLi `HTTP 403`) + kết quả chạy `node tests/run-rate-limit-test.js` (`HTTP 429`).
18. **Ảnh #18:** *AWS Billing and Cost Management -> Budgets* (khóa trần 200 USD) kèm tab *FinOps & Cost* trên giao diện Web Cloud Media Studio.
