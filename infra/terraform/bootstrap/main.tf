# Bootstrap: the S3 bucket that stores Terraform state for the environments.
#
# Run this once, before any environment. The bucket has to exist before an
# environment can use it as a backend, so this small configuration keeps its
# own state in a local file (ignored by git).

terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.28"
    }
  }
}

variable "aws_region" {
  description = "Region of the state bucket."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to sign in with. Null falls back to AWS_PROFILE or the default profile."
  type        = string
  default     = "my-account"
}

variable "aws_account_id" {
  description = "The 12-digit account the lab belongs to. Set it in terraform.tfvars, which git ignores."
  type        = string
  default     = null
}

variable "state_bucket_name" {
  description = "Name of the state bucket. Bucket names are unique across all of AWS."
  type        = string
  default     = "ecs-lab-tfstate-04c8bbc2"
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  # When aws_account_id is set, Terraform refuses to run against any other account.
  allowed_account_ids = var.aws_account_id == null ? null : [var.aws_account_id]
}

resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name

  tags = {
    Name      = var.state_bucket_name
    Terraform = "true"
    Purpose   = "terraform-state"
  }

  # The state is the only record of what Terraform created. Never delete it by accident.
  lifecycle {
    prevent_destroy = true
  }
}

# Keep every earlier version of the state, so a bad write can be rolled back.
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Old state versions are small, but there is no reason to keep them forever.
resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  depends_on = [aws_s3_bucket_versioning.state]
}

# Refuse any request that does not use TLS.
resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.state.arn,
          "${aws_s3_bucket.state.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.state]
}

output "state_bucket_name" {
  description = "Use this as the bucket in each environment's backend block."
  value       = aws_s3_bucket.state.id
}
