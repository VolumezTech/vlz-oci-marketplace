resource "oci_core_security_list" "volumez_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vlz_vcn.id
  display_name   = "volumez-sl-${random_string.deploy_id.result}"

  # Ingress rules
  dynamic "ingress_security_rules" {
    for_each = [8009, 3260]
    content {
      protocol    = "6"  # TCP
      source      = [var.subnet_cidr_block_list]
      description = "TCP port ${ingress_security_rules.value}"
      tcp_options {
        min = ingress_security_rules.value
        max = ingress_security_rules.value
      }
    }
  }

    ingress_security_rules {
    protocol    = "6"  # TCP
    source      = "0.0.0.0/0"
    description = "SSH traffic"
    tcp_options {
        min = ingress_security_rules.value
        max = ingress_security_rules.value
    }
  }

  # ICMP rule
  ingress_security_rules {
    protocol    = "1"  # ICMP
    source      = [var.subnet_cidr_block_list]
    description = "ICMP traffic"
    icmp_options {
      type = 3
      code = 4
    }
  }

  # Egress rule
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    description = "Allow all outbound traffic"
  }

  # Optional: Add tags if needed
  freeform_tags = {
    "Name"      = "volumez-sl"
    "Terraform" = "true"
  }
}
