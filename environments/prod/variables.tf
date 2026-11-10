variable "aws_region" {
  description = "AWS Region triển khai hạ tầng"
  type        = string
  default     = "ap-southeast-1"
}

variable "image_tag" {
  type        = string
  description = "Exact immutable image tag; supplied by deployment workflow."
  validation {
    condition     = can(regex("^v-[0-9a-f]{40}$", var.image_tag))
    error_message = "image_tag must be v- followed by a full lowercase Git SHA."
  }
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
