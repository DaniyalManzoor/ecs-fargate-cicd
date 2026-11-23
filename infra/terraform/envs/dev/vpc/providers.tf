provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  # When aws_account_id is set, Terraform refuses to run against any other
  # account. This protects against applying with the wrong AWS profile.
  allowed_account_ids = var.aws_account_id == null ? null : [var.aws_account_id]

  # Every resource gets these tags, so cost and ownership are always traceable.
  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      Stack       = "vpc"
      ManagedBy   = "terraform"
    }
  }
}
