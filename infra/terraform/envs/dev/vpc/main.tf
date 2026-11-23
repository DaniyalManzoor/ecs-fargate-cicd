# The VPC stack of one environment. This file is the same in every
# environment; the values come from the environment's .auto.tfvars file.

locals {
  name = "${var.project}-${var.environment}"
}

module "vpc" {
  source = "../../../modules/vpc"

  name = local.name
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  single_nat_gateway = var.single_nat_gateway

  enable_flow_logs         = var.enable_flow_logs
  flow_logs_retention_days = var.flow_logs_retention_days
}
