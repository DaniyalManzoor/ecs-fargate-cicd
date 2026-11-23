# Other stacks of this environment, such as the backend, read these outputs.

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
  value       = module.vpc.availability_zones
}

output "public_subnet_ids" {
  description = "Public subnets, one per zone. Load balancers go here."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnets, one per zone. ECS tasks go here."
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateways. These are billed by the hour."
  value       = module.vpc.nat_gateway_ids
}

output "nat_public_ips" {
  description = "Public addresses that outbound traffic from the private subnets appears to come from."
  value       = module.vpc.nat_public_ips
}
