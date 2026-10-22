# File: bootstrap/outputs.tf (Phụ trách: Thành viên 1)
output "s3_state_bucket_name" {
  description = "Tên S3 Bucket lưu trữ Terraform State"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "aws_role_arn_for_github_secrets" {
  description = "Copy giá trị này lưu vào GitHub Secrets với tên AWS_ROLE_ARN"
  value       = aws_iam_role.github_actions_oidc_role.arn
}
