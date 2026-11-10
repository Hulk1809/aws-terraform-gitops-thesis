variable "environment" {
  type = string
}

variable "image_tag" {
  type        = string
  description = "Immutable image tag built from the full Git commit SHA."
  validation {
    condition     = can(regex("^v-[0-9a-f]{40}$", var.image_tag))
    error_message = "image_tag must be v- followed by a full lowercase Git SHA."
  }
}

variable "public_subnet_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "ecr_repository_url" {
  type        = string
  description = "URL của kho Amazon ECR để EC2 kéo ảnh tự động qua User Data"
}
