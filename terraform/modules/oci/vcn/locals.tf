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

  security_list_egress_all = {
    destination      = "0.0.0.0/0"
    protocol         = "all"
    description      = "All Traffic For All Port"
    destination_type = "CIDR_BLOCK"
  }

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

  security_list_ingress_worker_1 = {
    protocol    = "all"
    source      = var.subnet_worker_cidr_block
    description = "Allow pods on one worker node to communicate with pods on other worker nodes."
    source_type = "CIDR_BLOCK"

  }

  security_list_ingress_worker_2 = {
    protocol    = "all"
    source      = var.subnet_k8s_cidr_block
    description = "Allow Kubernetes control plane to communicate with worker nodes."
    source_type = "CIDR_BLOCK"
  }

  security_list_ingress_worker_3 = {
    protocol    = local.ip_protocols.ICMP
    source      = "0.0.0.0/0"
    description = "Path Discovery"
    source_type = "CIDR_BLOCK"
    icmp_type   = 3
    icmp_code   = 4
  }

  security_list_ingress_worker_4 = {
    protocol                 = local.ip_protocols.TCP
    source                   = var.subnet_lb_cidr_block
    description              = "Inbound Public LB traffic to worker nodes."
    source_type              = "CIDR_BLOCK"
    tcp_destination_port_min = local.node_port_min
    tcp_destination_port_max = local.node_port_max
  }

  security_list_ingress_worker_5 = {
    protocol                 = local.ip_protocols.TCP
    source                   = var.subnet_lb_cidr_block
    description              = "Allow load balancer to communicate with kube-proxy on worker nodes."
    source_type              = "CIDR_BLOCK"
    tcp_destination_port_min = local.health_check_port
    tcp_destination_port_max = local.health_check_port
  }

  security_list_egress_worker_1 = {
    destination      = var.subnet_k8s_cidr_block
    protocol         = local.ip_protocols.TCP
    description      = "Kubernetes worker to Kubernetes API endpoint communication."
    destination_type = "CIDR_BLOCK"
  }

  security_list_egress_worker_2 = {
    destination      = "0.0.0.0/0"
    protocol         = local.ip_protocols.ICMP
    description      = "Path discovery"
    destination_type = "CIDR_BLOCK"
    icmp_type        = 3
    icmp_code        = 4
  }

  security_list_ingress_lb_1 = {
    protocol                 = local.ip_protocols.TCP
    source                   = "0.0.0.0/0"
    description              = "Inbound http traffic."
    source_type              = "CIDR_BLOCK"
    tcp_destination_port_min = local.http_port
    tcp_destination_port_max = local.http_port
  }

  security_list_ingress_lb_2 = {
    protocol                 = local.ip_protocols.TCP
    source                   = "0.0.0.0/0"
    description              = "Inbound https traffic."
    source_type              = "CIDR_BLOCK"
    tcp_destination_port_min = local.https_port
    tcp_destination_port_max = local.https_port
  }

  ingress_rules_k8s    = [local.security_list_ingress_k8s_1, local.security_list_ingress_k8s_2, local.security_list_ingress_k8s_3]
  egress_rules_k8s     = [local.security_list_egress_k8s_1, local.security_list_egress_ons]

  ingress_rules_lb    = [local.security_list_ingress_lb_1, local.security_list_ingress_lb_1]
  egress_rules_lb     = [local.security_list_egress_all]

  ingress_rules_wrk    = [local.security_list_ingress_worker_1, local.security_list_ingress_worker_2, local.security_list_ingress_worker_3,local.security_list_ingress_worker_4,local.security_list_ingress_worker_5]
  egress_rules_wrk     = [local.security_list_egress_worker_1, local.security_list_egress_worker_2,local.security_list_egress_ons]

  subnet_map = {
    VM-Subnet = {
      name                       = "${var.building_block}-${var.env}-vm-subnet"
      description                = "VM Subnet"
      dns_label                  = "vmsubnet"
      cidr_block                 = var.subnet_vm_cidr_block
      prohibit_public_ip_on_vnic = true
    }
    K8S-Subnet = {
      name                       = "${var.building_block}-${var.env}-k8s-subnet"
      description                = "K8S Subnet"
      dns_label                  = "kbsubnet"
      cidr_block                 = var.subnet_k8s_cidr_block
      prohibit_public_ip_on_vnic = false
    }
    WRK-Subnet = {
      name                       = "${var.building_block}-${var.env}-wrk-subnet"
      description                = "Worker Subnet"
      dns_label                  = "wrksubnet"
      cidr_block                 = var.subnet_worker_cidr_block
      prohibit_public_ip_on_vnic = true
    }
    LB-Subnet = {
      name                       = "${var.building_block}-${var.env}-lb-subnet"
      description                = "LB Subnet"
      dns_label                  = "lbsubnet"
      cidr_block                 = var.subnet_lb_cidr_block
      prohibit_public_ip_on_vnic = false
    }
  }
}
