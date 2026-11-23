# VPC module: public and private subnets across the given zones, an internet
# gateway, NAT for the private subnets, a free S3 gateway endpoint and
# optional flow logs. Every environment calls this module with its own values.

data "aws_region" "current" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.8.0"

  name = var.name
  cidr = var.cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_dns_support   = true
  enable_dns_hostnames = true

  # NAT gateways are billed by the hour. One shared gateway is cheapest; one
  # per zone keeps the other zones online when a zone fails.
  enable_nat_gateway     = true
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = !var.single_nat_gateway

  # The tier tag lets other stacks find the right subnets by tag.
  public_subnet_tags  = { Tier = "public" }
  private_subnet_tags = { Tier = "private" }

  # Flow logs record accepted and rejected traffic for audits and debugging.
  enable_flow_log                                 = var.enable_flow_logs
  create_flow_log_cloudwatch_log_group            = var.enable_flow_logs
  create_flow_log_cloudwatch_iam_role             = var.enable_flow_logs
  flow_log_cloudwatch_log_group_retention_in_days = var.flow_logs_retention_days
  flow_log_max_aggregation_interval               = 60

  tags = var.tags
}

# S3 gateway endpoint: free, and keeps ECR layer downloads off the NAT gateway.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids

  tags = merge(var.tags, {
    Name = "${var.name}-vpce-s3"
  })
}
