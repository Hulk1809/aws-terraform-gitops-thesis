# Trạng thái nghiệm thu

Không đánh dấu AWS đạt chỉ vì CI xanh. Điền link run/ảnh thật sau từng lần kiểm chứng, không đưa credential/state/plan binary vào repository công khai.

| Kịch bản | Code | Kiểm chứng AWS |
|---|---|---|
| 1. OIDC keyless | main-only trust, id-token permission | Chưa chạy lại pipeline tích hợp |
| 2. Native lock | S3 backend, use_lockfile, concurrency chung | Chưa gây xung đột lock trên AWS |
| 3. Registry/dashboard | Immutable ECR, lifecycle, exact SHA, IMDSv2 sanitized JSON | Chưa chạy User Data trên EC2 |
| 4. Security gates | Checkov, Trivy không ignore-unfixed, HTTP smoke test | Chưa chụp negative PR test trên GitHub |
| 5. FinOps | Giới hạn tài nguyên, Infracost $20 list-price gate/comment | Thiếu INFRACOST_API_KEY; chưa dự toán thật |
| 6. Drift/self-healing | Exit 0/1/2, Issue, saved-plan reconcile, post-plan verify | Chưa tạo drift/reconcile trên AWS |
| 7. Budget/billing | Budget $1, actual >1% cảnh báo email | Chưa kiểm chứng email hoặc hóa đơn; không cam kết $0 |

## Minh chứng local

- Terraform prod `init -backend=false` và `validate`: không gọi AWS backend.
- Checkov modules: ghi kết quả run thực tế trong PR tích hợp; skip có lý do không tính thành check bảo mật đạt.
- Docker: build image, HTTP GET, Git SHA, FinOps self-test qua `bash tests/check.sh`.
- Trivy: kết quả chỉ có giá trị với digest và cơ sở CVE tại lần chạy; không bảo đảm không có lỗ hổng tương lai.

## Kiểm thử AWS khi sẵn sàng

1. TV1 xác nhận account/region/chi phí, chạy plan rồi apply theo README; lưu link Actions OIDC/apply.
2. TV2 lấy public IP, kiểm tra cloud-init và container, chụp runtime instance ID/region/AZ/uptime và Git SHA khớp ECR tag.
3. TV3 chụp ECR settings/lifecycle và Trivy; đo dung lượng image, không suy ra dưới 500 MB từ số tag.
4. TV1 giữ một Terraform process đang nắm lock rồi chạy process khác trên cùng backend để chụp lỗi lock. Không dùng `-lock=false`, không xóa lock đang hoạt động.
5. TV3 thêm Infracost API key; PR thử `t3.medium` phải bị static gate chặn và có dự toán tăng giá. Đóng PR thử, không merge.
6. Bật drift, sửa một tag không nhạy cảm, chạy detect để mở Issue; chạy thủ công `auto_reconcile=true`, xác nhận plan sau apply exit 0 và Issue đóng.
7. Chụp Budget/email/billing thật; ghi số tiền thật. Tắt drift, destroy prod với `DESTROY`, kiểm tra tài nguyên còn sót. Không destroy bootstrap.
