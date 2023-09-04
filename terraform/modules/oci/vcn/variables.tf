
variable "env" {
  type        = string
  description = "Environment name. All resources will be prefixed with this value."
}

variable "building_block" {
  type        = string
  description = "Building block name. All resources will be prefixed with this value."
}

variable "vcn_cidr" {
  type        = list(string)
  description = "VCN CIDR range"
  default     = ["10.10.0.0/16"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDR values."
  default     = ["10.10.0.0/28", "10.10.1.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDR values."
  default     = ["10.10.3.0/24", "10.10.2.0/24"]
}

variable "compartment_id" {
 type        = string
 description = "The OCID of the compartment to contain the VCN."
}
