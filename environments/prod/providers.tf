provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "AWS-Terraform-Registry-GitOps-Thesis"
      Environment = var.environment
      ManagedBy   = "Terraform-GitHubActions-OIDC"
    }
  }
}
