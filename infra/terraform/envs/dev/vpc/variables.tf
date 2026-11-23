# ---- Who and where -----------------------------------------------------------

variable "project" {
  description = "Project name. It starts every resource name and fills the Project tag."
  type        = string
}

variable "environment" {
  description = "Environment name, for example dev or prod."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging or prod."
  }
}

variable "aws_region" {
  description = "Region for every resource in this stack. The zones in azs must belong to it."
  type        = string
}

variable "aws_profile" {
  description = "AWS CLI profile to sign in with. Null falls back to AWS_PROFILE or the default profile."
  type        = string
  default     = null
}

variable "aws_account_id" {
  description = "The 12-digit account this environment belongs to. Required. Set it in terraform.tfvars, which git ignores."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be exactly 12 digits."
  }
}

# ---- Network -----------------------------------------------------------------

variable "vpc_cidr" {
  description = "IPv4 address range of the VPC. Each environment needs its own range."
  type        = string
}

variable "azs" {
  description = "Availability Zones to use."
  type        = list(string)
}

variable "private_subnets" {
  description = "Address ranges of the private subnets, one per zone."
  type        = list(string)
}

variable "public_subnets" {
  description = "Address ranges of the public subnets, one per zone."
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "True creates one shared NAT gateway. False creates one per zone."
  type        = bool
}

variable "enable_flow_logs" {
  description = "True sends VPC flow logs to CloudWatch."
  type        = bool
}

variable "flow_logs_retention_days" {
  description = "Days to keep flow logs in CloudWatch."
  type        = number
  default     = 30
}
