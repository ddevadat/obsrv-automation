terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

######################################################################
#                      Create VCN                                    # 
######################################################################
resource "oci_core_vcn" "vcn" {
  cidr_blocks    = var.vcn_cidr
  compartment_id = var.compartment_id
  display_name   = "${var.building_block}-${var.env}-vcn"
}