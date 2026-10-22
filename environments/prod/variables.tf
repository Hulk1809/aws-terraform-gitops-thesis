variable "aws_region" {
  description = "AWS Region triển khai hạ tầng"
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Tên môi trường"
  type        = string
  default     = "prod"
}

variable "ecr_repository_name" {
  description = "Tên Amazon ECR repository"
  type        = string
  default     = "thesis-cloud-app-repo"
}

variable "alert_email" {
  description = "Email nhận cảnh báo AWS Budgets; truyền bằng TF_VAR_alert_email"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "alert_email phải là địa chỉ email hợp lệ."
  }
}
