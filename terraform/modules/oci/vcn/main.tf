terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

# -----------------------------------------------------------------------------
# Create VCN
# -----------------------------------------------------------------------------
resource "oci_core_vcn" "vcn" {
  cidr_blocks    = var.vcn_cidr
  compartment_id = var.compartment_id
  display_name   = "${var.building_block}-${var.env}-vcn"
  dns_label = "obsrvcn"
}


# -----------------------------------------------------------------------------
# Create NAT Gateway
# -----------------------------------------------------------------------------
resource "oci_core_nat_gateway" "nat-gw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.building_block}-${var.env}-nat-gw"
}

# -----------------------------------------------------------------------------
# Create Internet Gateway
# -----------------------------------------------------------------------------
resource "oci_core_internet_gateway" "int-gw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.building_block}-${var.env}-int-gw"
}

# -----------------------------------------------------------------------------
# Create Service Gateway
# -----------------------------------------------------------------------------


resource "oci_core_service_gateway" "svc-gw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  services {
    service_id = lookup(data.oci_core_services.all_services.services[0], "id")
  }
  display_name = "${var.building_block}-${var.env}-svc-gw"
}

# -----------------------------------------------------------------------------
# Create Route Table
# -----------------------------------------------------------------------------
resource "oci_core_route_table" "public_route_table" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.building_block}-${var.env}-public-rt"
  dynamic "route_rules" {
    for_each = local.private_route_rules.route_rules
    content {
      description       = route_rules.key
      network_entity_id = route_rules.value.network_entity_id
      destination       = route_rules.value.destination
      destination_type  = route_rules.value.destination_type
    }
  }
}

resource "oci_core_route_table" "private_route_table" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.building_block}-${var.env}-private-rt"
  dynamic "route_rules" {
    for_each = local.public_route_rules.route_rules
    content {
      description       = route_rules.key
      network_entity_id = route_rules.value.network_entity_id
      destination       = route_rules.value.destination
      destination_type  = route_rules.value.destination_type
    }
  }
}

# -----------------------------------------------------------------------------
# Create Security Rules
# -----------------------------------------------------------------------------
module "k8s_security_list" {
  source                     = "../security_list"
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.vcn.id
  security_list_display_name = "${var.building_block}-${var.env}-k8s-security-list"
  egress_rules               = local.egress_rules_k8s
  ingress_rules              = local.ingress_rules_k8s
}

module "worker_security_list" {
  source                     = "../security_list"
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.vcn.id
  security_list_display_name = "${var.building_block}-${var.env}-wrk-security-list"
  egress_rules               = local.egress_rules_wrk
  ingress_rules              = local.ingress_rules_wrk
}

module "lb_security_list" {
  source                     = "../security_list"
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.vcn.id
  security_list_display_name = "${var.building_block}-${var.env}-lb-security-list"
  egress_rules               = local.egress_rules_lb
  ingress_rules              = local.ingress_rules_lb
}

# -----------------------------------------------------------------------------
# Create Subnet
# -----------------------------------------------------------------------------

module "k8s_subnet" {
  source = "../subnet"
  subnet_map            = { Workload-Spoke-WorkerNode-Subnet = local.subnet_map.K8S-Subnet }
  compartment_id        = var.compartment_id
  vcn_id                = oci_core_vcn.vcn.id
  subnet_route_table_id = oci_core_route_table.public_route_table.id
  subnet_security_list_id = toset([
    module.k8s_security_list.security_list_id
  ])
}

module "wrk_subnet" {
  source = "../subnet"
  subnet_map            = { Workload-Spoke-WorkerNode-Subnet = local.subnet_map.WRK-Subnet }
  compartment_id        = var.compartment_id
  vcn_id                = oci_core_vcn.vcn.id
  subnet_route_table_id = oci_core_route_table.private_route_table.id
  subnet_security_list_id = toset([
    module.worker_security_list.security_list_id
  ])
}

module "lb_subnet" {
  source = "../subnet"
  subnet_map            = { Workload-Spoke-WorkerNode-Subnet = local.subnet_map.LB-Subnet }
  compartment_id        = var.compartment_id
  vcn_id                = oci_core_vcn.vcn.id
  subnet_route_table_id = oci_core_route_table.public_route_table.id
  subnet_security_list_id = toset([
    module.lb_security_list.security_list_id
  ])
}