locals {
  workload_nat_gw_check      = var.enable_nat_gateway == true ? var.nat_gw_check : []
  workload_service_gw_check  = var.enable_service_gateway == true ? var.service_gw_check : []
  workload_internet_gw_check = var.enable_internet_gateway == true ? var.internet_gw_check : []

  route_rules_options = {
    route_rules_nat = {
      for index, route in local.workload_nat_gw_check : "nat-gw-rule-${index}" => {
        network_entity_id = oci_core_nat_gateway.nat-gw.id
        destination       = "0.0.0.0/0"
        destination_type  = "CIDR_BLOCK"
      }
    }
    route_rules_int = {
      for index, route in local.workload_internet_gw_check : "int-gw-rule-${index}" => {
        network_entity_id = oci_core_internet_gateway.int-gw.id
        destination       = "0.0.0.0/0"
        destination_type  = "CIDR_BLOCK"
      }
    }
    route_rules_srvc_gw = {
      for index, route in local.workload_service_gw_check : "service-gw-rule-${index}" => {
        network_entity_id = oci_core_service_gateway.svc-gw.id
        destination       = data.oci_core_services.service_gateway.services[0]["cidr_block"]
        destination_type  = "SERVICE_CIDR_BLOCK"

      }
    }

  }
  private_route_rules = {
    route_rules = merge(local.route_rules_options.route_rules_nat, local.route_rules_options.route_rules_srvc_gw)
  }

  public_route_rules = {
    route_rules = merge(local.route_rules_options.route_rules_int)
  }

  ip_protocols = {
    ICMP   = "1"
    TCP    = "6"
    UDP    = "17"
    ICMPv6 = "58"
  }

  # Port numbers
  all_ports         = -1
  apiserver_port    = 6443
  health_check_port = 10256
  kubelet_api_port  = 10250
  oke_port          = 12250
  node_port_min     = 30000
  node_port_max     = 32767
  ssh_port          = 22
  https_port        = 443
  http_port         = 80

  security_list_ingress_k8s_1 = {
    protocol                 = local.ip_protocols.TCP
    source                   = "0.0.0.0/0"
    description              = "Kubernetes API endpoint communication"
    source_type              = "CIDR_BLOCK"
    tcp_destination_port_min = local.apiserver_port
    tcp_destination_port_max = local.apiserver_port
  }

  security_list_ingress_k8s_2 = {
    protocol                 = local.ip_protocols.TCP
    source                   = var.subnet_worker_cidr_block
    description              = "Kubernetes worker to control plane communication"
    source_type              = "CIDR_BLOCK"
    tcp_destination_port_min = local.oke_port
    tcp_destination_port_max = local.oke_port
  }

  security_list_ingress_k8s_3 = {
    protocol    = local.ip_protocols.ICMP
    source      = var.subnet_worker_cidr_block
    description = "Path Discovery"
    source_type = "CIDR_BLOCK"
    icmp_type   = 3
    icmp_code   = 4
  }

  security_list_egress_ons = {
    destination              = lookup(data.oci_core_services.all_services.services[0], "cidr_block")
    protocol                 = local.ip_protocols.TCP
    description              = "Allow Kubernetes control plane to communicate with OKE"
    destination_type         = "SERVICE_CIDR_BLOCK"
  }

  security_list_egress_k8s_1 = {
    destination      = var.subnet_worker_cidr_block
    protocol         = "all"
    description      = "All traffic to worker nodes"
    destination_type = "CIDR_BLOCK"
  }

  ingress_rules_k8s    = [local.security_list_ingress_k8s_1, local.security_list_ingress_k8s_2, local.security_list_ingress_k8s_3]
  egress_rules_k8s     = [local.security_list_egress_k8s_1, local.security_list_egress_ons]
}
