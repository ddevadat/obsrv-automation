#Get Service Gateway For Region .
data "oci_core_services" "service_gateway" {
  filter {
    name   = "name"
    values = [".*Object.*Storage"]
    regex  = true
  }
}

data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

# data "oci_core_services" "service_gateway_all_oci_services" {
#   filter {
#     name   = "name"
#     values = ["All .* Services In Oracle Services Network"]
#     regex  = true
#   }
# }