module "vpc" {
  source = "../../modules/vpc"

  environment        = var.environment
  aws_region         = var.aws_region
  vpc_cidr           = "10.0.0.0/16"
  public_subnet_cidr = "10.0.1.0/24"
}

module "ecr_registry" {
  source = "../../modules/ecr-registry"

  environment     = var.environment
  repository_name = var.ecr_repository_name
}

module "compute_ec2" {
  source = "../../modules/compute-ec2"

  environment        = var.environment
  aws_region         = var.aws_region
  public_subnet_id   = module.vpc.public_subnet_id
  security_group_id  = module.vpc.web_sg_id
  ecr_repository_url = module.ecr_registry.repository_url
}
