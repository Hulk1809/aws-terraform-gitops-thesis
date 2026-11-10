# Báo cáo kỹ thuật — Terraform, Registry và GitHub Actions trên AWS

> Bản nội dung kỹ thuật dùng chung, không phải báo cáo thực nghiệm đã nghiệm thu. Ảnh, kết quả AWS và hóa đơn phải bổ sung bằng dữ liệu thật theo ACCEPTANCE.md.

## Mở đầu — TV1

Quản lý tài nguyên bằng Console khó tái lập, khó review và dễ bỏ sót tài nguyên tính phí. Đồ án dùng Terraform để khai báo hạ tầng, Git để lưu phiên bản và GitHub Actions làm điểm kiểm soát thay đổi. Mục tiêu là tái tạo môi trường demo có xác thực tạm thời, kiểm tra bảo mật, quản lý image, dự toán chi phí và thu hồi tài nguyên. Giới hạn: một môi trường lab, một EC2, không HA, không cam kết hóa đơn bằng không.

## Chương 1. Cơ sở lý thuyết — TV1/TV2

### 1.1. Infrastructure as Code

Terraform xây dựng dependency graph từ cấu hình, đối chiếu state và AWS API để tạo plan. Apply thực thi plan; state ánh xạ resource address với resource ID. Code tái lập cấu hình, không tự thay thế backup dữ liệu ứng dụng. Module tách interface input/output để tái sử dụng VPC, compute và registry.

### 1.2. GitOps và OIDC

PR cung cấp lịch sử thay đổi và quality gate. Main là nguồn cấu hình chuẩn; không triển khai code nhánh thành viên bằng role AWS. GitHub cấp OIDC token; AWS STS kiểm tra audience và subject rồi cấp credential tạm thời. Không lưu access key dài hạn trong GitHub. Bảo vệ nhánh và giới hạn workflow bổ sung cho trust policy, không thay thế least privilege IAM.

### 1.3. Hai loại Registry

Terraform Module Registry phân phối module theo version và interface. Amazon ECR lưu OCI/container image theo tag và digest. Repo này có module layout và Git versioning; chưa xuất bản private Module Registry. Immutable ECR tag `v-<Git SHA>` giúp liên kết image với commit; lifecycle hạn chế bản cũ nhưng không giới hạn tổng byte tức thì.

### 1.4. State và S3 native lock

Prod state nằm S3 có versioning, AES256 và Block Public Access. Terraform 1.10+ dùng `use_lockfile=true`; lock tránh hai tiến trình cập nhật state đồng thời. `.terraform.lock.hcl` khóa provider version/checksum, khác với S3 `.tflock` khóa thao tác state. State/plan có thể chứa dữ liệu nhạy cảm nên không commit hoặc đăng lên Issue.

## Chương 2. Vấn đề và rủi ro — TV2/TV3

### 2.1. Danh tính và bảo mật

Static key có vòng đời dài, dễ lộ qua code/log. OIDC giảm nhu cầu giữ key nhưng role quá rộng vẫn gây rủi ro. Instance profile cung cấp quyền pull ECR cho EC2. IMDSv2 yêu cầu token; host chỉ xuất allowlist instance ID/region/AZ/boot time, không chuyển IAM credentials hoặc token cho browser/container.

### 2.2. Thiếu chuẩn hóa module và image

Copy code thủ công gây lệch interface; image mutable làm mất truy vết phiên bản. Module output/input thống nhất trong composition và full-prod validate phát hiện lỗi nối module. Image tag theo full SHA, digest base được khóa và Trivy kiểm tra trước push. Không dùng image “mới nhất” hoặc fallback app vì có thể che lỗi triển khai.

### 2.3. Chi phí và drift

NAT Gateway, KMS customer key, EC2/EBS/IPv4 và tài nguyên bỏ quên có thể tạo phí. Free Tier thay đổi theo tài khoản; credit không phải giá dịch vụ bằng không. Infracost ước tính giá niêm yết, Budget cảnh báo thực chi có độ trễ. Sửa Console tạo drift; plan exit code 2 cần phân biệt với exit code 1 là lỗi, không tự apply khi chưa được cho phép.

## Chương 3. Thiết kế và triển khai — TV1/TV2/TV3

### 3.1. Mạng và compute

VPC/subnet public dùng IGW, không NAT/EIP. Default SG đóng, web SG mở HTTP demo, egress DNS/HTTP/HTTPS; không mở SSH công khai. EC2 t3.micro có 8 GiB gp3 encrypted, IMDSv2 required và CPU credits standard. Public IPv4 có thể tính phí. User Data cài Docker, đăng nhập ECR bằng instance role, pull tag đã chỉ định và mount metadata JSON read-only. Thay User Data thay instance, chấp nhận downtime của lab.

### 3.2. ECR và pipeline image

ECR immutable, scan-on-push, AES256, force-delete phục vụ teardown. Lifecycle xóa untagged sau một ngày và giữ ba tagged image prefix `v`. CD tạo ECR trước để phá vòng phụ thuộc registry/image/EC2; build và Trivy phải thành công trước full apply. Không bỏ qua CVE HIGH/CRITICAL chưa có bản vá. Quét không chứng minh không tồn tại CVE chưa được công bố.

### 3.3. FinOps

Static gate giới hạn loại/số EC2, ổ đĩa và dịch vụ ngoài scope. Khi có Infracost API key, workflow dự toán, kiểm tra trần $20/tháng giá niêm yết và comment PR. Chưa có key phải báo chưa chạy dự toán. AWS Budget $1 với actual >1% cảnh báo khi chi phí vượt $0.01; không tự tắt tài nguyên và không bảo đảm báo tức thì.

### 3.4. CI/CD và quản trị

PR chạy format, validate từng module và prod, Checkov, Docker build/HTTP/Git SHA, Trivy và FinOps. Main được bảo vệ bởi required checks. Merge tích hợp giữ contribution của các nhánh thành viên. Auto-deploy có gate mặc định false; plan thủ công không apply. Destroy yêu cầu xác nhận DESTROY, giới hạn thư mục prod. Bootstrap giữ riêng để không mất backend/OIDC.

### 3.5. Drift và self-healing

Drift chỉ bật sau triển khai; dùng state output để giữ image đang chạy. Plan phân biệt 0/1/2, chỉ Issue exit 2, không đăng raw state/plan lên Issue công khai. Reconcile thủ công trên main dùng saved plan rồi plan lại xác nhận không lệch. CD và drift chung concurrency; S3 lock bảo vệ cả thao tác local. Chưa bổ sung GitHub environment để tránh đổi OIDC subject ngoài trust hiện tại.

## Kết quả, hạn chế và kết luận

Kết quả code và kiểm tra local/CI được ghi tại PR tích hợp. Bảy kịch bản AWS còn cần minh chứng thật theo ACCEPTANCE.md; chưa được khẳng định dashboard, self-healing, email Budget hoặc billing đã đạt. Thiếu Infracost API key là phụ thuộc bên ngoài không thể tạo bằng code. Private Module Registry, IAM triển khai least privilege chi tiết, HTTPS/domain và HA chưa thuộc bản lab hiện tại.

Giải pháp tạo quy trình quản lý vòng đời có thể review, tái lập và dọn dẹp thay vì chỉ triển khai một website. Nghiệm thu phải dựa vào log/ảnh thực tế, số tiền thực và kiểm tra tài nguyên sau destroy, không dựa riêng vào CI xanh.

## Tài liệu tham khảo

- Terraform S3 backend: https://developer.hashicorp.com/terraform/language/backend/s3
- Terraform modules: https://developer.hashicorp.com/terraform/language/modules
- GitHub OIDC AWS: https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws
- ECR lifecycle: https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html
- AWS Budgets: https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html
- Infracost: https://www.infracost.io/docs/
- Trivy: https://trivy.dev/latest/docs/
