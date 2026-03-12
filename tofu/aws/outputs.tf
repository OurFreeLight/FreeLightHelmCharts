output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = var.enable_eks ? module.kubernetes[0].cluster_endpoint : null
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = var.enable_eks ? module.kubernetes[0].cluster_name : null
}

output "eks_update_kubeconfig_command" {
  description = "Command to update kubeconfig for this cluster"
  value       = var.enable_eks ? "aws eks update-kubeconfig --name ${module.kubernetes[0].cluster_name} --region ${var.region}" : null
}

output "static_site_urls" {
  description = "CloudFront URLs for static sites"
  value       = { for k, v in module.static_site : k => v.cloudfront_domain }
}

output "rds_endpoint" {
  description = "RDS PostgreSQL primary endpoint (writes + reads)"
  value       = var.enable_rds ? module.database[0].endpoint : null
}

output "rds_reader_endpoints" {
  description = "RDS read replica endpoints (reads only)"
  value       = var.enable_rds ? module.database[0].reader_endpoints : []
}

output "cache_endpoint" {
  description = "ElastiCache endpoint"
  value       = var.enable_cache ? module.cache[0].endpoint : null
}

# --- S3 Storage ---

output "s3_uploads_bucket" {
  description = "S3 bucket name for DAO file uploads"
  value       = module.storage.uploads_bucket_name
}

output "s3_backups_bucket" {
  description = "S3 bucket name for database backups"
  value       = module.storage.backups_bucket_name
}

output "s3_access_key_id" {
  description = "IAM access key for S3 (use from any cloud provider)"
  value       = module.storage.access_key_id
}

output "s3_secret_access_key" {
  description = "IAM secret key for S3 (use from any cloud provider)"
  value       = module.storage.secret_access_key
  sensitive   = true
}

output "s3_region" {
  description = "AWS region for S3 buckets"
  value       = module.storage.region
}
