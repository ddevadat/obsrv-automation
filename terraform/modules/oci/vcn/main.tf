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
}


# -----------------------------------------------------------------------------
# Create NAT Gateway
# -----------------------------------------------------------------------------
resource "oci_core_nat_gateway" "nat-gw" {
  compartment_id = var.compartment_id
  vcn_id = oci_core_vcn.vcn.id
  display_name = "${var.building_block}-${var.env}-nat-gw"
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

data "oci_core_services" "service_gateway_all_oci_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}


resource "oci_core_service_gateway" "svc-gw" {
  compartment_id = var.compartment_id
  vcn_id          = oci_core_vcn.vcn.id
  services {
        service_id = lookup(data.oci_core_services.service_gateway_all_oci_services.services[0], "id")
  }
  display_name = "${var.building_block}-${var.env}-svc-gw"
}