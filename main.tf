provider "oci" {
  auth   = "InstancePrincipal"
  region = var.region # Reference the region variable
}

resource "null_resource" "singup_user" {
  provisioner "local-exec" {
    command = "scripts/singup_user.sh ${var.email} ${var.password}"
  }
}

### Random
resource "random_string" "deploy_id" {
  length  = 4
  special = false
}

### SSH
resource "tls_private_key" "public_private_key_pair" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

### Network
resource "oci_core_vcn" "vlz_vcn" {
  cidr_block     = "10.1.0.0/16"
  compartment_id = var.tenancy_ocid
  display_name   = "VolumezVcn-${random_string.deploy_id.result}"
  dns_label      = "volumezvcn"
}

resource "oci_core_internet_gateway" "vlz_internet_gateway" {
  compartment_id = var.tenancy_ocid
  display_name   = "VolumezInternetGateway-${random_string.deploy_id.result}"
  vcn_id         = oci_core_vcn.vlz_vcn.id
}

resource "oci_core_route_table" "vlz_route_table" {
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.vlz_vcn.id
  display_name   = "VolumezRouteTable-${random_string.deploy_id.result}"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.vlz_internet_gateway.id
  }
}

resource "oci_core_subnet" "vlz_subnet" {
  count = length(var.subnet_cidr_block_list)

  availability_domain = local.availability_domain
  cidr_block          = var.subnet_cidr_block_list[count.index]
  display_name        = "VlzSubnet-${count.index}-${random_string.deploy_id.result}"
  dns_label           = "vlzsubnet${count.index}"
  security_list_ids   = [oci_core_security_list.volumez_sl.id]
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.vlz_vcn.id
  route_table_id      = oci_core_route_table.vlz_route_table.id
  dhcp_options_id     = oci_core_vcn.vlz_vcn.default_dhcp_options_id
}

resource "oci_cluster_placement_groups_cluster_placement_group" "vlz_cluster_pg" {
  count = local.num_of_pgs

  availability_domain          = local.availability_domain
  cluster_placement_group_type = "STANDARD"
  compartment_id               = var.tenancy_ocid
  description                  = "bla"
  name                         = "cluster_pg-${random_string.deploy_id.result}"
}

### Compute
# Media #
resource "oci_core_instance_configuration" "media_instance_configuration" {
  compartment_id = var.tenancy_ocid
  display_name   = "media_instance-${random_string.deploy_id.result}"

  instance_details {
    instance_type = "compute"

    launch_details {
      compartment_id             = var.tenancy_ocid
      shape                      = var.media_shape
      cluster_placement_group_id = local.media_cluster_pg_or_null

      dynamic "shape_config" {
        for_each = var.media_ignore_cpu_mem_req ? [] : [1]
        content {
          # memory_in_gbs = var.media_memory_in_gbs
          ocpus = local.media_num_of_ocpus
        }
      }

      source_details {
        source_type             = "image"
        boot_volume_size_in_gbs = 60
        image_id                = "ocid1.image.oc1..aaaaaaaae4o5zvaipl7xmspt3fhvzntb23vq42jszowjbso4kcl4lwzjy73a"
      }
      launch_options {
        network_type = "VFIO"
      }

      metadata = {
        ssh_authorized_keys = var.generate_public_ssh_key ? tls_private_key.public_private_key_pair.public_key_openssh : "${tls_private_key.public_private_key_pair.public_key_openssh}${var.public_ssh_key}"
        user_data           = data.cloudinit_config.operator.rendered
      }
    }
  }
}

resource "oci_core_instance_pool" "media_instance_pool" {
  count = local.num_of_instance_pools

  compartment_id            = var.tenancy_ocid
  instance_configuration_id = oci_core_instance_configuration.media_instance_configuration.id
  display_name              = format("media-instance-pool-${random_string.deploy_id.result}-%s", count.index)

  placement_configurations {
    availability_domain = local.availability_domain
    primary_subnet_id   = oci_core_subnet.vlz_subnet[count.index].id
    fault_domains       = local.fault_domains
  }
  size = local.instances_per_pool_list[count.index]

  timeouts {
    create = "10m"
  }
}

# Application #
resource "oci_core_instance_configuration" "app_instance_configuration" {
  compartment_id = var.tenancy_ocid
  display_name   = "app_instance-${random_string.deploy_id.result}"

  instance_details {
    instance_type = "compute"

    launch_details {
      compartment_id             = var.tenancy_ocid
      shape                      = var.app_shape
      cluster_placement_group_id = local.app_cluster_pg_or_null

      dynamic "shape_config" {
        for_each = var.app_ignore_cpu_mem_req ? [] : [1]
        content {
          memory_in_gbs = local.app_memory_in_gbs
          ocpus         = local.app_num_of_ocpus
        }
      }

      source_details {
        source_type             = "image"
        boot_volume_size_in_gbs = 60
        image_id                = "ocid1.image.oc1..aaaaaaaae4o5zvaipl7xmspt3fhvzntb23vq42jszowjbso4kcl4lwzjy73a"
      }

      create_vnic_details {
        subnet_id                 = oci_core_subnet.vlz_subnet[0].id
        assign_private_dns_record = true
        assign_public_ip          = true
        display_name              = "vlz-prime-vnic-${random_string.deploy_id.result}"
      }

      launch_options {
        network_type = "VFIO"

      }

      metadata = {
        ssh_authorized_keys = var.generate_public_ssh_key ? tls_private_key.public_private_key_pair.public_key_openssh : "${tls_private_key.public_private_key_pair.public_key_openssh}${var.public_ssh_key}"
        user_data           = data.cloudinit_config.operator.rendered
      }
    }
  }
}

resource "oci_core_instance_pool" "app_instance_pool" {
  count                     = var.app_num_of_instances > 0 ? 1 : 0
  compartment_id            = var.tenancy_ocid
  instance_configuration_id = oci_core_instance_configuration.app_instance_configuration.id
  display_name              = "app-instance-pool-${random_string.deploy_id.result}"
  placement_configurations {
    availability_domain = local.availability_domain
    primary_subnet_id   = oci_core_subnet.vlz_subnet[0].id
    fault_domains       = local.fault_domains
  }
  size = var.app_num_of_instances

  timeouts {
    create = "10m"
  }
}

resource "null_resource" "run_python_script" {
  provisioner "local-exec" {
    command = "python scripts/vlz_api.py ${var.email} ${var.password} ${var.env_size}"
  }

  depends_on = [
    oci_core_instance_pool.app_instance_pool,
    oci_core_instance_pool.media_instance_pool
  ]
}

resource "null_resource" "install_postgress" {
  count = var.app_num_of_instances
  provisioner "file" {
    source      = "scripts/postgresql/"
    destination = "/tmp/"

    connection {
      type        = "ssh"
      host        = data.oci_core_instance.app_instance[count.index].public_ip
      user        = "ubuntu"
      private_key = tls_private_key.public_private_key_pair.private_key_pem
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_pg_v3.bash",
      "sudo bash /tmp/install_pg_v3.bash ${var.postgres_version}"
    ]

    connection {
      type        = "ssh"
      host        = data.oci_core_instance.app_instance[count.index].public_ip
      user        = "ubuntu"
      private_key = tls_private_key.public_private_key_pair.private_key_pem
    }
  }

  depends_on = [oci_core_instance_pool.app_instance_pool, null_resource.run_python_script]

}

resource "null_resource" "destroy" {
  triggers = {
    email    = var.email
    password = var.password
  }

  provisioner "local-exec" {
    when    = destroy
    command = "scripts/tenant_cleanup.sh ${self.triggers.email} ${self.triggers.password}"
  }
}
