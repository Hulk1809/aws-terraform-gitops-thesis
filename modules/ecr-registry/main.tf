resource "aws_ecr_repository" "app_repo" {
  #checkov:skip=CKV_AWS_136: Project specification requires AES256 encryption; KMS is intentionally omitted to keep key management simple and avoid additional cost in the AWS Free Tier demo.
  name                 = var.repository_name
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Environment = var.environment
    CostTier    = "FreeTier-Under-500MB"
  }
}

resource "aws_ecr_lifecycle_policy" "free_tier_saver" {
  repository = aws_ecr_repository.app_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 1 day"

        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }

        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep at most 3 tagged images with v prefix"

        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 3
        }

        action = {
          type = "expire"
        }
      }
    ]
  })
}
