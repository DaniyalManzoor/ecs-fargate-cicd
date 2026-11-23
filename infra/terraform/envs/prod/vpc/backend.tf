# Terraform state for this stack lives in S3, not on one computer.
# The bucket is created by ../../../bootstrap. Each stack has its own key,
# so a mistake in one stack cannot damage the state of another.

terraform {
  backend "s3" {
    bucket = "ecs-lab-tfstate-04c8bbc2"
    key    = "prod/vpc/terraform.tfstate"
    region = "us-east-1"

    # The AWS CLI profile to sign in with. A backend block cannot read
    # variables, so the name is written here as well as in prod.auto.tfvars.
    profile = "my-account"

    encrypt = true

    # Lock the state with a lock file in the bucket, so two runs cannot
    # write at the same time. No DynamoDB table is needed.
    use_lockfile = true
  }
}
