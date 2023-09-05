
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

variable "subnet_lb_cidr_block" {
  type        = string
  description = "LB Subnet CIDR block"
  default     = "10.10.1.0/24"
}

variable "subnet_k8s_cidr_block" {
  type        = string
  description = "K8S Subnet CIDR block"
  default     = "10.10.0.0/28"
}

variable "subnet_worker_cidr_block" {
  type        = string
  description = "Worker Subnet CIDR block"
  default     = "10.10.2.0/24"
}

variable "subnet_vm_cidr_block" {
  type        = string
  description = "VM Subnet CIDR block"
  default     = "10.10.3.0/24"
}

variable "compartment_id" {
  type        = string
  description = "The OCID of the compartment to contain the VCN."
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}
variable "enable_service_gateway" {
  type    = bool
  default = true
}
variable "enable_internet_gateway" {
  type    = bool
  default = true
}

variable "nat_gw_check" {
  type    = list(string)
  default = [""]
}

variable "service_gw_check" {
  type    = list(string)
  default = [""]
}

variable "internet_gw_check" {
  type    = list(string)
  default = [""]
}

