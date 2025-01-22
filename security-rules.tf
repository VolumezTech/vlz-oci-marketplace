# resource "oci_core_security_list" "volumez-sl" {
#   compartment_id = var.compartment_ocid
#   vcn_id         = oci_core_vcn.vlz_vcn.id
#   display_name   = "volumez-sl-${random_string.deploy_id.result}"

#   egress_security_rules {
#     protocol         = "all"
#     destination      = "0.0.0.0/0"
#     destination_type = "CIDR_BLOCK"
#   }

#   ingress_security_rules {
#     protocol    = "6"
#     tcp_options {
#       source_port_range {
#         min = 22
#         max = 22
#       }
#     }
#     source      = "0.0.0.0/0"
#     source_type = "CIDR_BLOCK"
#   }

#   ingress_security_rules {
#     protocol    = "6"
#     tcp_options {
#       source_port_range {
#         min = 8009
#         max = 8009
#       }
#     }
#     source      = "0.0.0.0/0"
#     source_type = "CIDR_BLOCK"
#   }
# }

resource "oci_core_network_security_group" "volumez-sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vlz_vcn.id
  display_name   = "volumez-sl-${random_string.deploy_id.result}"
}

resource "oci_core_network_security_group_security_rule" "ingress_rules" {
  for_each = {
    22    = "SSH"
    8009  = "Custom 8009"
    3260  = "iSCSI"
    8000  = "Custom 8000"
    8082  = "Custom 8082"
    80    = "HTTP"
    8765  = "Custom 8765"
    9092  = "Kafka"
    47604 = "Custom 47604"
    8443  = "HTTPS Alt"
    5986  = "WinRM HTTPS"
    5149  = "Custom 5149"
    8999  = "Custom 8999"
    443   = "HTTPS"
    3000  = "Custom 3000"
    6068  = "Custom 6068"
  }

  network_security_group_id = oci_core_network_security_group.node_sg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = "10.1.20.0/24"
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      min = each.key
      max = each.key
    }
  }
  description = each.value
}

resource "oci_core_network_security_group_security_rule" "icmp_rule" {
  network_security_group_id = oci_core_network_security_group.node_sg.id
  direction                 = "INGRESS"
  protocol                  = "1" # ICMP
  source                    = "10.1.20.0/24"
  source_type               = "CIDR_BLOCK"
  icmp_options {
    type = 3
    code = 4
  }
  description = "ICMP"
}

resource "oci_core_network_security_group_security_rule" "egress_rule" {
  network_security_group_id = oci_core_network_security_group.node_sg.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "10.1.20.0/24"
  destination_type          = "CIDR_BLOCK"
  description               = "Allow all outbound traffic"
}
