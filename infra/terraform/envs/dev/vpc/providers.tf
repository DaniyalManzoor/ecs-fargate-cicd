provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  # Terraform refuses to run against any other account. This protects against
  # applying with the wrong AWS profile. The variable has no default, so a
  # stack without a terraform.tfvars file fails instead of running unguarded.
  allowed_account_ids = [var.aws_account_id]

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
