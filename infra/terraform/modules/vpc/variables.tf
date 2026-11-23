variable "name" {
  description = "Name of the VPC. Subnets, gateways and route tables get names that start with it."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,40}$", var.name))
    error_message = "name must be 3 to 40 characters: lower-case letters, digits and hyphens."
  }
}

variable "cidr" {
  description = "IPv4 address range of the VPC, for example 10.0.0.0/16. Ranges of different environments must not overlap."
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr, 0))
    error_message = "cidr must be a valid IPv4 range such as 10.0.0.0/16."
  }
}

variable "azs" {
  description = "Availability Zones to use. A load balancer needs at least two."
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 2
    error_message = "Give at least two Availability Zones."
  }
}

variable "private_subnets" {
  description = "Address ranges of the private subnets, one per zone. Workloads such as ECS tasks go here."
  type        = list(string)

  validation {
    condition     = length(var.private_subnets) == length(var.azs)
    error_message = "Give exactly one private subnet range per Availability Zone."
  }
}

variable "public_subnets" {
  description = "Address ranges of the public subnets, one per zone. Load balancers and NAT gateways go here."
  type        = list(string)

  validation {
    condition     = length(var.public_subnets) == length(var.azs)
    error_message = "Give exactly one public subnet range per Availability Zone."
  }
}

variable "single_nat_gateway" {
  description = "True creates one shared NAT gateway. False creates one per zone, which costs more and survives a zone failure."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "True sends VPC flow logs to a CloudWatch log group."
  type        = bool
  default     = false
}

variable "flow_logs_retention_days" {
  description = "Days to keep flow logs in CloudWatch."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Extra tags for every resource in the VPC. Common tags come from the provider's default_tags."
  type        = map(string)
  default     = {}
}
