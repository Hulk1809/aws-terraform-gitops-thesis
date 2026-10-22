output "application_url" {
  description = "URL HTTP của ứng dụng demo"
  value       = "http://${module.compute_ec2.public_ip}"
}

output "ec2_public_ip" {
  description = "Public IPv4 của EC2"
  value       = module.compute_ec2.public_ip
}

output "ecr_registry_url" {
  description = "URL Amazon ECR repository"
  value       = module.ecr_registry.repository_url
}
