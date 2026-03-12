# S3 bucket for application file storage (uploads, backups, etc.)
# This is always AWS — usable from any cloud provider's K8s cluster.

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

variable "name_prefix" {
  type = string
}

variable "enable_backups_bucket" {
  description = "Create a separate bucket for database backups"
  type        = bool
  default     = false
}

variable "lifecycle_rules" {
  description = "Enable lifecycle rules for cost optimization"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Days to keep backups before transitioning to cheaper storage"
  type        = number
  default     = 30
}

# --- Uploads Bucket ---

resource "aws_s3_bucket" "uploads" {
  bucket = "${var.name_prefix}-uploads"

  tags = { Name = "${var.name_prefix}-uploads" }
}

resource "aws_s3_bucket_versioning" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_cors_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = ["*"]
    max_age_seconds = 3600
  }
}

# --- Backups Bucket (optional) ---

resource "aws_s3_bucket" "backups" {
  count  = var.enable_backups_bucket ? 1 : 0
  bucket = "${var.name_prefix}-backups"

  tags = { Name = "${var.name_prefix}-backups" }
}

resource "aws_s3_bucket_versioning" "backups" {
  count  = var.enable_backups_bucket ? 1 : 0
  bucket = aws_s3_bucket.backups[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  count  = var.enable_backups_bucket ? 1 : 0
  bucket = aws_s3_bucket.backups[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backups" {
  count  = var.enable_backups_bucket ? 1 : 0
  bucket = aws_s3_bucket.backups[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  count  = var.enable_backups_bucket && var.lifecycle_rules ? 1 : 0
  bucket = aws_s3_bucket.backups[0].id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    filter {}

    transition {
      days          = var.backup_retention_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.backup_retention_days * 3
      storage_class = "GLACIER"
    }
  }
}

# --- IAM User for cross-cloud access ---
# When K8s runs on GCP/DO, pods can't use IRSA.
# This IAM user provides access keys for the DAO API to reach S3.

resource "aws_iam_user" "storage" {
  name = "${var.name_prefix}-storage"

  tags = { Name = "${var.name_prefix}-storage" }
}

resource "aws_iam_access_key" "storage" {
  user = aws_iam_user.storage.name
}

data "aws_iam_policy_document" "storage" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = concat(
      [
        aws_s3_bucket.uploads.arn,
        "${aws_s3_bucket.uploads.arn}/*",
      ],
      var.enable_backups_bucket ? [
        aws_s3_bucket.backups[0].arn,
        "${aws_s3_bucket.backups[0].arn}/*",
      ] : []
    )
  }
}

resource "aws_iam_user_policy" "storage" {
  name   = "${var.name_prefix}-storage-access"
  user   = aws_iam_user.storage.name
  policy = data.aws_iam_policy_document.storage.json
}

# --- Outputs ---

output "uploads_bucket_name" {
  value = aws_s3_bucket.uploads.bucket
}

output "uploads_bucket_arn" {
  value = aws_s3_bucket.uploads.arn
}

output "backups_bucket_name" {
  value = var.enable_backups_bucket ? aws_s3_bucket.backups[0].bucket : null
}

output "backups_bucket_arn" {
  value = var.enable_backups_bucket ? aws_s3_bucket.backups[0].arn : null
}

output "region" {
  value = data.aws_region.current.name
}

data "aws_region" "current" {}

output "access_key_id" {
  description = "IAM access key for cross-cloud S3 access"
  value       = aws_iam_access_key.storage.id
}

output "secret_access_key" {
  description = "IAM secret key for cross-cloud S3 access"
  value       = aws_iam_access_key.storage.secret
  sensitive   = true
}
