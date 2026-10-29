variable "environment" {
  type = string
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