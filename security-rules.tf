resource "oci_core_security_list" "volumez-sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vlz_vcn.id
  display_name   = "volumez-sl-${random_string.deploy_id.result}"

  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
  }

  ingress_security_rules {
    protocol    = "6"
    tcp_options {
      source_port_range {
        min = 22
        max = 22
      }
    }
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
  }

  ingress_security_rules {
    protocol    = "6"
    tcp_options {
      source_port_range {
        min = 8009
        max = 8009
      }
    }
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
  }
}

