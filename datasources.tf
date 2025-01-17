locals {
  operator_template = "${path.module}/cloudinit/deploy_connector.template.yaml"
}

# data "oci_core_images" "ubuntu_24_04" {
#   compartment_id           = var.compartment_ocid
#   operating_system         = "Canonical Ubuntu"
#   operating_system_version = "24.04"
#   shape                    = var.media_shape
#   sort_by                  = "TIMECREATED"
#   sort_order               = "DESC"
# }

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = var.ad_number
}

data "cloudinit_config" "operator" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "operator.yaml"
    content_type = "text/cloud-config"
    content = templatefile(
      local.operator_template, {
        operator_timezone   = "Asia/Jerusalem",
        email               = var.email,
        password            = var.password,
        vlz_rest_apigw      = var.vlz_rest_apigw,
        vlz_s3_path_to_conn = var.vlz_s3_path_to_conn,
      }
    )
  }
}

### App Data ###
data "oci_core_instance_pool_instances" "app_pool" {
  depends_on = [oci_core_instance_pool.app_instance_pool]
  count      = var.app_num_of_instances > 0 ? 1 : 0

  compartment_id   = var.tenancy_ocid
  instance_pool_id = oci_core_instance_pool.app_instance_pool[0].id
}

data "oci_core_instance" "app_instance" {
  count = var.app_num_of_instances

  instance_id = data.oci_core_instance_pool_instances.app_pool[0].instances[count.index].id
}


### Media Data ###

data "oci_core_instance_pool_instances" "media_pool" {
  depends_on = [oci_core_instance_pool.media_instance_pool]
  count      = local.media_num_of_instances > 0 ? 1 : 0

  compartment_id   = var.tenancy_ocid
  instance_pool_id = oci_core_instance_pool.media_instance_pool[0].id
}

data "oci_core_instance" "media_instance" {
  count       = local.media_num_of_instances
  instance_id = data.oci_core_instance_pool_instances.media_pool[0].instances[count.index].id
}
