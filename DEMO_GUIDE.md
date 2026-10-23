# QUY TRÌNH DEMO ĐỒ ÁN TERRAFORM – AWS – GITHUB ACTIONS

> Tài liệu dùng chung cho nhóm 3 thành viên. Đọc toàn bộ trước buổi demo, sau đó mỗi người luyện đúng phần được giao.

## 1. Mục tiêu đồ án

Đồ án xây dựng quy trình quản lý toàn bộ vòng đời hạ tầng và ứng dụng container trên AWS bằng mã nguồn:

```text
Thành viên sửa code trên nhánh riêng
                 ↓
          Tạo Pull Request
                 ↓
 GitHub Actions kiểm tra tự động
 fmt + validate + Checkov + Docker build
                 ↓
          Merge vào main
                 ↓
 GitHub OIDC cấp quyền AWS tạm thời
                 ↓
 Terraform plan/apply hạ tầng AWS
                 ↓
 VPC + EC2 + ECR + IAM + AWS Budget
                 ↓
 EC2 kéo image từ ECR và chạy web
                 ↓
 Drift Detection phát hiện sửa tay
                 ↓
 Terraform destroy dọn môi trường
```

### Vấn đề được giải quyết

| Vấn đề | Giải pháp trong đồ án |
|---|---|
| Tạo tài nguyên thủ công, khó tái lập | Terraform Infrastructure as Code |
| Lộ AWS Access Key | GitHub OIDC + credential tạm thời |
| Code lỗi được đưa lên AWS | Pull Request + CI validation |
| Cấu hình hạ tầng thiếu an toàn | Checkov |
| Container có lỗ hổng | Trivy |
| Image lưu thiếu kiểm soát | Amazon ECR + lifecycle policy |
| Không biết thay đổi tốn bao nhiêu | Infracost + AWS Budget |
| Hạ tầng bị sửa trực tiếp trên Console | Drift Detection + Self-Healing |
| Quên tắt tài nguyên | Terraform Destroy |

## 2. Kiến trúc và luồng dữ liệu

```text
GitHub Repository
├── bootstrap/              TV1: S3 state + GitHub OIDC role
├── modules/vpc/            TV2: mạng AWS
├── modules/compute-ec2/    TV2: EC2 + IAM Instance Profile + User Data
├── modules/ecr-registry/   TV3: Amazon ECR
├── app-demo/               TV3: Docker app
├── environments/prod/      TV1: kết nối 3 module + AWS Budget
└── .github/workflows/      CI/CD, image pipeline, drift detection
```

Quan hệ giữa module:

```text
VPC output: subnet_id + security_group_id ─┐
                                           ├─→ EC2
ECR output: repository_url ────────────────┘
```

EC2 dùng IAM Instance Profile để đọc ECR. Không lưu Access Key trong EC2 hoặc User Data.

## 3. Phân công trình bày

### Thành viên 1 — Nhóm trưởng

Phụ trách trình bày:

- Kiến trúc tổng thể và GitOps.
- GitHub Repository, nhánh và Pull Request.
- S3 Remote State, mã hóa, versioning và native lockfile.
- GitHub OIDC và IAM Role.
- `environments/prod` composition.
- Workflow `plan/apply/destroy`.
- AWS Budget và kết thúc bằng `destroy`.

### Thành viên 2 — VPC và EC2

Phụ trách trình bày:

- Module VPC, public subnet, Internet Gateway và route table.
- Security Group và nguyên tắc cổng tối thiểu.
- Lý do không dùng NAT Gateway và Elastic IP.
- EC2 `t3.micro`, EBS 8 GiB `gp3`, mã hóa, IMDSv2.
- IAM Role/Instance Profile chỉ đọc ECR.
- User Data cài Docker, kéo image và chạy ứng dụng.
- Website trên Public IP.

### Thành viên 3 — ECR, App, Security, FinOps và Drift

Phụ trách trình bày:

- ECR immutable tags, scan on push, AES256 và lifecycle policy.
- Dockerfile Alpine và ứng dụng demo.
- Pipeline build, Trivy scan và push ECR.
- Infracost.
- Drift Detection, GitHub Issue và Self-Healing.

## 4. Quy tắc an toàn bắt buộc

1. Không hiển thị hoặc gửi AWS Access Key, Secret Key, token, file `.pem`.
2. Không đăng nhập root để thao tác thường xuyên trong buổi demo.
3. Không push trực tiếp vào `main`.
4. Không chạy `apply` trước khi xem `plan`.
5. Không chạy `destroy` trong thư mục `bootstrap/`.
6. Chỉ destroy môi trường tại `environments/prod/`.
7. Không tạo NAT Gateway, Elastic IP, RDS, Load Balancer hoặc KMS Customer Managed Key.
8. Chỉ giữ một EC2 `t3.micro`.
9. Không mở SSH `0.0.0.0/0`.
10. Chụp đủ minh chứng trước khi destroy.

## 5. Điều kiện trước buổi demo

### 5.1. Code phải đầy đủ

- [ ] `modules/vpc/main.tf`, `variables.tf`, `outputs.tf`.
- [ ] `modules/compute-ec2/main.tf`, `variables.tf`, `outputs.tf`.
- [ ] `modules/ecr-registry/main.tf`, `variables.tf`, `outputs.tf`.
- [ ] `app-demo/Dockerfile` và `app-demo/index.html`.
- [ ] `environments/prod/` validate thành công.
- [ ] Bốn workflow theo đề cương đã có trên `main`.
- [ ] Mọi PR cần thiết đã merge; không còn Draft PR chặn composition.

### 5.2. GitHub phải sẵn sàng

- [ ] Branch `main` được bảo vệ.
- [ ] Required checks đang bật.
- [ ] Secret `AWS_ROLE_ARN` tồn tại.
- [ ] Secret `TF_VAR_ALERT_EMAIL` tồn tại.
- [ ] Secret `INFRACOST_API_KEY` tồn tại nếu demo Infracost.
- [ ] Variable `AWS_AUTO_DEPLOY` được kiểm tra trước buổi demo.

### 5.3. AWS phải sạch trước apply

- [ ] Region là `ap-southeast-1`.
- [ ] Không còn EC2 tạo thủ công.
- [ ] Không có Elastic IP dư.
- [ ] Không có EBS volume `available` dư.
- [ ] S3 bootstrap bucket vẫn tồn tại.
- [ ] GitHub OIDC Provider và role vẫn tồn tại.

### 5.4. Trạng thái hiện tại của dự án

Tại thời điểm tạo tài liệu:

- Bootstrap S3/OIDC: đã hoàn thành.
- Workflow validation TV2/TV3: đã hoạt động.
- CD workflow: đã tạo nhưng `AWS_AUTO_DEPLOY=false`.
- Composition TV1: đang ở Draft PR #5, chờ module TV2/TV3.
- Không được bật auto-deploy đến khi cả ba module validate thành công.

## 6. Kịch bản demo đầy đủ

### Bước 1 — Giới thiệu đề tài (TV1, 2 phút)

Mở sơ đồ kiến trúc hoặc cây thư mục repository.

Nói:

> Đồ án dùng Terraform, GitHub Actions và Registry để quản lý hạ tầng AWS bằng mã nguồn. Mọi thay đổi đi qua Pull Request, được kiểm tra tự động, rồi GitHub Actions dùng OIDC để nhận quyền AWS tạm thời và triển khai. Hệ thống còn kiểm soát container, bảo mật, chi phí, drift và thu hồi tài nguyên.

Minh chứng:

- Repository và cấu trúc thư mục.
- Ba module Terraform.
- Danh sách workflow.

### Bước 2 — Quy trình cộng tác Git (TV1, 2 phút)

Mở một Pull Request thật của TV2 hoặc TV3.

Chỉ rõ:

- Thành viên làm trên nhánh riêng.
- Không push trực tiếp `main`.
- Required checks phải xanh.
- Lịch sử commit và người thực hiện được lưu lại.

Nói:

> Git là nguồn cấu hình chuẩn. Pull Request tạo điểm kiểm soát trước khi mã nguồn có thể ảnh hưởng AWS.

### Bước 3 — CI và Shift-Left Security (TV1 + TV2/TV3, 3 phút)

Trong PR, mở các checks:

- `Validate modules/vpc`.
- `Validate modules/compute-ec2`.
- `Validate modules/ecr-registry`.
- Checkov scans.
- Docker build.

Nếu có thời gian, dùng PR demo lỗi:

1. Cố tình mở SSH cho `0.0.0.0/0` hoặc đặt ECR `MUTABLE`.
2. Cho thấy Checkov báo đỏ.
3. Sửa lại.
4. Cho thấy check xanh.

Nói:

> Lỗi được phát hiện trước triển khai, thay vì chờ đến khi tài nguyên đã chạy trên AWS.

### Bước 4 — OIDC Keyless Authentication (TV1, 3 phút)

Trên GitHub mở:

```text
Settings → Secrets and variables → Actions
```

Chỉ tên `AWS_ROLE_ARN`. Không mở giá trị secret. Chứng minh không có:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

Trên AWS mở:

```text
IAM → Identity providers → token.actions.githubusercontent.com
IAM → Roles → Thesis-GitHubActions-OIDC-Role → Trust relationships
```

Chỉ điều kiện nhánh:

```text
repo:Hulk1809/aws-terraform-gitops-thesis:ref:refs/heads/main
```

Nói:

> GitHub nhận credential tạm thời qua OIDC. Credential hết hiệu lực sau phiên chạy và nhánh thành viên không thể dùng role triển khai.

### Bước 5 — S3 Remote State và Lockfile (TV1, 3 phút)

Mở `environments/prod/backend.tf`, chỉ:

```hcl
backend "s3" {
  bucket       = "thangvq-thesis-tfstate-2026-freetier"
  key          = "prod/infrastructure.tfstate"
  region       = "ap-southeast-1"
  encrypt      = true
  use_lockfile = true
}
```

Trên S3 chỉ:

- Versioning Enabled.
- AES256 encryption.
- Block Public Access.
- State object sau lần apply đầu tiên.

Nếu demo tranh chấp khóa, mở hai terminal chạy đồng thời `plan/apply`; tiến trình thứ hai phải báo lỗi lock. Không dùng `-lock=false`.

Nói:

> State cho Terraform biết tài nguyên nào trong AWS thuộc cấu hình. Lockfile ngăn hai tiến trình thay đổi state cùng lúc.

### Bước 6 — Review VPC và EC2 code (TV2, 4 phút)

TV2 mở module và giải thích:

- VPC CIDR `10.0.0.0/16`.
- Public subnet `10.0.1.0/24`.
- Internet Gateway và default route.
- Không có NAT Gateway.
- Ingress HTTP 80; SSH không mở công khai.
- Egress đủ DNS/HTTP/HTTPS theo thiết kế.
- EC2 `t3.micro`, EBS 8 GiB `gp3`, encrypted.
- IMDSv2 `http_tokens = "required"`.
- CPU credits `standard` nếu module áp dụng.
- IAM Instance Profile chỉ đọc ECR.
- User Data không chứa Access Key.

Nói:

> EC2 chỉ chạy ứng dụng. Docker build và scan chạy trên GitHub Actions để tránh tiêu tốn RAM EC2.

### Bước 7 — Review ECR và ứng dụng (TV3, 4 phút)

TV3 mở module ECR và Dockerfile:

- `image_tag_mutability = "IMMUTABLE"`.
- Scan on push.
- AES256.
- `force_delete = true` phục vụ teardown.
- Xóa untagged image và giữ tối đa ba bản.
- Base image Alpine nhỏ.

Mở pipeline container và chỉ luồng:

```text
Build → Trivy scan → Login ECR bằng OIDC → Push
```

Nói:

> ECR là nguồn lưu container tập trung. Immutable tag và Git SHA giúp truy vết chính xác phiên bản đã triển khai.

### Bước 8 — Terraform Plan (TV1, 3 phút)

Trên GitHub:

```text
Actions → 02 - CD Terraform Apply → Run workflow → action: plan
```

Đọc plan trước khi apply. Plan hợp lệ phải chỉ có tài nguyên trong phạm vi đồ án.

Không được có:

- NAT Gateway.
- Elastic IP.
- Load Balancer.
- RDS.
- KMS Customer Managed Key.
- EC2 lớn hơn `t3.micro`.
- Nhiều hơn một EC2.

Nói:

> Plan là bước xem trước. Nhóm kiểm tra phạm vi, bảo mật và rủi ro chi phí trước khi thay đổi AWS.

### Bước 9 — Terraform Apply (TV1, 5–10 phút)

Chỉ chạy sau khi plan đúng:

```text
Actions → 02 - CD Terraform Apply → Run workflow → action: apply
```

Theo dõi các bước:

1. Configure AWS credentials through OIDC.
2. Terraform init.
3. Format/validate.
4. Plan.
5. Apply.

Không đóng trang nếu job đang chạy. Nếu apply lỗi, không bấm chạy liên tục; đọc lỗi trước.

### Bước 10 — Kiểm tra tài nguyên AWS (TV1 + TV2 + TV3, 5 phút)

TV2 kiểm tra:

- VPC, subnet, route và Security Group.
- Một EC2 `t3.micro` đang chạy.
- EBS 8 GiB, gp3, encrypted.
- IMDSv2 và IAM Instance Profile.

TV3 kiểm tra:

- ECR repository.
- Immutable tags, scan on push, encryption.
- Image tag/Git SHA và lifecycle policy.

TV1 kiểm tra:

- AWS Budget.
- S3 state object.
- Log OIDC/apply.

### Bước 11 — Mở ứng dụng (TV2 + TV3, 2 phút)

Lấy Public IPv4 của EC2, mở:

```text
http://PUBLIC_IP
```

Nếu chưa lên ngay, chờ User Data hoàn tất rồi kiểm tra cloud-init/system log. Không thay đổi Security Group tùy tiện để chữa lỗi.

Nói:

> EC2 dùng Instance Role lấy image từ ECR, sau đó chạy container. Không có Access Key trong máy.

### Bước 12 — FinOps (TV1 + TV3, 3 phút)

TV1 mở AWS Budget:

```text
Thesis-FreeTier-Zero-Spend-Alert
```

Giải thích budget `$1`, threshold 1%, tương đương cảnh báo từ `$0.01`.

TV3 mở comment Infracost trên PR thử đổi `t3.micro` thành cấu hình lớn hơn. Không merge PR thử này.

Nói:

> Infracost dự toán trước triển khai; AWS Budget theo dõi chi phí thật. Budget là cảnh báo, không phải cơ chế tự chặn hóa đơn.

### Bước 13 — Drift Detection và Self-Healing (TV3 + TV1, 4 phút)

1. Sửa một tag ít nguy hiểm trên AWS Console.
2. Chạy workflow drift detection.
3. Chỉ exit code `2` và GitHub Issue cảnh báo.
4. Chạy reconcile nếu workflow hỗ trợ.
5. Chứng minh tag trở lại trạng thái trong Git.

Không tạo drift bằng cách mở SSH công khai.

Nói:

> Git là nguồn sự thật. Mọi thay đổi ngoài quy trình đều được phát hiện và có thể đưa trở lại cấu hình chuẩn.

### Bước 14 — Native Lock Conflict (TV1, tùy thời gian)

Chỉ thực hiện khi nhóm đã luyện trước:

1. Chạy một tác vụ Terraform giữ lock.
2. Chạy tác vụ thứ hai trên cùng state.
3. Chụp lỗi lấy lock.
4. Chỉ `.tflock` trong S3.

Không xóa lock thủ công khi tiến trình đầu vẫn chạy.

### Bước 15 — Destroy và kiểm tra sau demo (TV1, bước cuối)

Trước destroy:

- [ ] Website đã chụp.
- [ ] EC2/VPC/ECR đã chụp.
- [ ] Workflow logs đã chụp.
- [ ] Budget và drift đã chụp.

Chạy:

```text
Actions → 02 - CD Terraform Apply → Run workflow → action: destroy
```

Sau destroy kiểm tra:

- Không còn EC2 chạy.
- Không còn EBS volume dư.
- Không có Elastic IP.
- VPC/ECR môi trường prod đã xóa.
- S3 bootstrap bucket còn nguyên.
- OIDC Provider và GitHub Actions Role còn nguyên.

Nói:

> Destroy thu hồi môi trường thử nghiệm để tránh chi phí. Code và bootstrap vẫn còn nên có thể tái tạo bằng apply.

## 7. Kịch bản demo rút gọn 10 phút

| Thời gian | Người | Nội dung |
|---:|---|---|
| 1 phút | TV1 | Mục tiêu và sơ đồ kiến trúc |
| 2 phút | TV1 | PR, CI checks, branch protection |
| 1 phút | TV1 | OIDC, không có Access Key |
| 2 phút | TV2 | VPC, EC2, IAM Instance Profile |
| 1 phút | TV3 | ECR, Docker, Trivy |
| 1 phút | Cả nhóm | Website đang chạy |
| 1 phút | TV3 | Drift hoặc Infracost |
| 1 phút | TV1 | Budget và Destroy |

## 8. Minh chứng cần chụp

### TV1

- [ ] Branch Protection và Required Checks.
- [ ] GitHub Secrets chỉ hiển thị tên, không có Access Key.
- [ ] OIDC Identity Provider.
- [ ] OIDC Role Trust Policy khóa vào `main`.
- [ ] S3 versioning, AES256 và Block Public Access.
- [ ] State object và `.tflock`.
- [ ] Plan/apply thành công.
- [ ] AWS Budget và email subscription.
- [ ] Destroy thành công.
- [ ] Billing/Cost Explorer tại thời điểm nghiệm thu.

### TV2

- [ ] VPC, subnet, Internet Gateway và route table.
- [ ] Security Group rules.
- [ ] EC2 `t3.micro`.
- [ ] EBS encrypted.
- [ ] IMDSv2 required.
- [ ] IAM Instance Profile.
- [ ] User Data/cloud-init log.
- [ ] Website trên Public IP.
- [ ] Checkov pass.

### TV3

- [ ] ECR immutable, scan on push và encryption.
- [ ] Lifecycle policy.
- [ ] Image tag theo Git SHA.
- [ ] Docker build thành công.
- [ ] Trivy pass.
- [ ] Infracost PR comment.
- [ ] Drift Issue.
- [ ] Self-Healing thành công.

## 9. Câu hỏi giảng viên có thể hỏi

### Tại sao dùng Terraform thay vì AWS Console?

Terraform lưu hạ tầng thành mã nguồn, hỗ trợ review, tái tạo, kiểm tra tự động và giảm sai sót thao tác tay.

### Tại sao dùng OIDC?

OIDC cấp credential AWS tạm thời cho workflow. Nhóm không lưu Access Key dài hạn trên GitHub.

### Terraform State để làm gì?

State ánh xạ resource trong code với tài nguyên thật trên AWS. S3 giúp dùng state tập trung; lockfile tránh hai tiến trình cập nhật đồng thời.

### Tại sao EC2 không build Docker image?

EC2 `t3.micro` có RAM thấp. GitHub runner build và scan; EC2 chỉ pull/run image nên nhẹ và ổn định hơn.

### Registry trong đề tài gồm gì?

Terraform module registry/pattern để tái sử dụng module và Amazon ECR để lưu Docker image có phiên bản.

### Checkov và Trivy khác nhau thế nào?

Checkov quét cấu hình IaC; Trivy quét lỗ hổng package trong container image.

### Infracost và AWS Budget khác nhau thế nào?

Infracost dự toán trước khi triển khai. AWS Budget theo dõi chi phí thực tế và gửi cảnh báo.

### Drift là gì?

Drift là khác biệt giữa cấu hình trong Git/Terraform và tài nguyên thật, thường do sửa trực tiếp trên Console.

### Destroy có làm mất code không?

Không. Destroy xóa tài nguyên prod do Terraform quản lý. Code GitHub, bootstrap S3 và OIDC được giữ riêng.

### Có bảo đảm hóa đơn `$0.00` không?

Không bảo đảm tuyệt đối vì Free Tier/credit tùy tài khoản và thời điểm. Đồ án tối ưu chi phí, tránh dịch vụ đắt tiền, dự toán, cảnh báo và thu hồi tài nguyên.

## 10. Xử lý lỗi nhanh

### Workflow không chạy

- Kiểm tra file đã nằm trên `main`.
- Kiểm tra trigger và path.
- Mở tab Actions xem workflow có bị disable không.

### OIDC báo không được assume role

- Workflow phải chạy từ `main`.
- Kiểm tra `AWS_ROLE_ARN`.
- Kiểm tra `permissions: id-token: write`.
- Kiểm tra Trust Policy đúng repository và branch.

### Terraform init lỗi backend

- Kiểm tra bucket bootstrap tồn tại.
- Kiểm tra region/key.
- Kiểm tra OIDC role có quyền S3 state và `.tflock`.

### Terraform validate lỗi module input/output

- So khớp `variables.tf` và `outputs.tf` của module với `environments/prod/main.tf`.
- Không sửa composition bằng cách đoán tên; thống nhất interface giữa thành viên.

### EC2 chạy nhưng website không lên

- Chờ cloud-init hoàn tất.
- Kiểm tra ECR đã có image đúng tag.
- Kiểm tra Instance Profile đọc ECR.
- Kiểm tra Security Group cổng 80.
- Kiểm tra User Data và Docker logs.

### Destroy lỗi ECR không rỗng

- ECR phải có `force_delete = true`.
- Không xóa state thủ công để né lỗi.

## 11. Checklist ngay trước khi đứng trình bày

- [ ] Ba thành viên biết đúng phần mình nói.
- [ ] Mỗi người đã luyện ít nhất một lần.
- [ ] Tất cả tab GitHub/AWS cần thiết được mở sẵn.
- [ ] Không tab nào hiển thị credential hoặc dữ liệu bí mật.
- [ ] Có bản quay/chụp dự phòng nếu mạng chậm.
- [ ] Plan đã được kiểm tra.
- [ ] Không còn EC2 thủ công.
- [ ] Email AWS Budget đã confirm.
- [ ] Đồng hồ phân chia thời gian rõ ràng.
- [ ] Một người thao tác, một người nói; tránh ba người cùng điều khiển.
- [ ] Destroy chỉ chạy sau khi giảng viên xem đủ minh chứng.

## 12. Thông điệp kết thúc

> Thành quả của nhóm không chỉ là một website chạy trên EC2. Thành quả chính là quy trình DevSecOps và FinOps quản lý toàn bộ vòng đời hạ tầng: viết mã, kiểm tra, xác thực không khóa, triển khai, quản lý container, kiểm soát chi phí, phát hiện sai lệch và thu hồi tài nguyên có thể tái tạo.
