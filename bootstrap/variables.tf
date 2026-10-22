# File: bootstrap/variables.tf (Phụ trách: Thành viên 1)
variable "aws_region" {
  type        = string
  description = "AWS Region triển khai hạ tầng"
  default     = "ap-southeast-1"
}

variable "state_bucket_name" {
  type        = string
  description = "Tên S3 Bucket lưu trữ State (Phải là duy nhất toàn cầu)"
  default     = "thangvq-thesis-tfstate-2026-freetier"
}

variable "github_repository" {
  type        = string
  description = "Tên GitHub Repo theo định dạng <username>/<repo_name>"
  default     = "Hulk1809/aws-terraform-gitops-thesis"
}
