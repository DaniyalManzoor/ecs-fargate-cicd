# Settings for the VPC of the dev environment. Terraform loads this file
# automatically, because its name ends in .auto.tfvars. Nothing here is private.
# The AWS account ID lives in terraform.tfvars in this folder, which git ignores.

project     = "ecs-lab"
environment = "dev"

aws_region  = "us-east-1"
aws_profile = "my-account"

vpc_cidr        = "10.0.0.0/16"
azs             = ["us-east-1a", "us-east-1b"]
private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

# Dev favours low cost: one shared NAT gateway and no flow logs.
single_nat_gateway = true
enable_flow_logs   = false
