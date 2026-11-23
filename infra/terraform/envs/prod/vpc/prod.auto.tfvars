# Settings for the VPC of the prod environment. Terraform loads this file
# automatically, because its name ends in .auto.tfvars. Nothing here is private.
# The AWS account ID lives in terraform.tfvars in this folder, which git ignores.

project     = "ecs-lab"
environment = "prod"

aws_region  = "us-east-1"
aws_profile = "my-account" # use a separate AWS account and profile for a real production

# A different range from dev, so the two networks can be connected later.
vpc_cidr        = "10.1.0.0/16"
azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
private_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
public_subnets  = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]

# Prod favours availability: one NAT gateway per zone, and flow logs kept for audits.
single_nat_gateway       = false
enable_flow_logs         = true
flow_logs_retention_days = 90
