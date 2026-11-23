output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "IPv4 address range of the VPC."
  value       = module.vpc.vpc_cidr_block
}

output "availability_zones" {
  description = "The zones the subnets were created in."
  value       = module.vpc.azs
}

output "public_subnet_ids" {
  description = "Public subnets, one per zone."
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "Private subnets, one per zone."
  value       = module.vpc.private_subnets
}

output "public_route_table_ids" {
  description = "Route tables of the public subnets."
  value       = module.vpc.public_route_table_ids
}

output "private_route_table_ids" {
  description = "Route tables of the private subnets."
  value       = module.vpc.private_route_table_ids
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateways."
  value       = module.vpc.natgw_ids
}

output "nat_public_ips" {
  description = "Public addresses that outbound traffic from the private subnets appears to come from."
  value       = module.vpc.nat_public_ips
}
