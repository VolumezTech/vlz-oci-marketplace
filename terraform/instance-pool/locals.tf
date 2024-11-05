locals {
  availability_domain = var.availability_domain_name != "" ? var.availability_domain_name: data.oci_identity_availability_domain.ad.name
  fault_domains = length(var.fault_domains) > 0 ? var.fault_domains : null
  # Env Sizes
  media_num_of_instances = (var.env_size == "Small" || var.env_size == "Medium") ? 2 : 4
  media_num_of_ocpus = (var.env_size == "Small") ? 8 : 16 

  app_num_of_ocpus = (var.env_size == "Small") ? 20 : var.env_size == "Medium" ? 48 : 96
  app_memory_in_gbs = (var.env_size == "Small") ? 64 : var.env_size == "Medium" ? 128 : 256

  num_of_subnets          = length(var.subnet_cidr_block_list)
  num_of_instance_pools   = local.media_num_of_instances == 0 ? 0 : (local.media_num_of_instances == 1 ? 1 : local.num_of_subnets)
  base_instances_per_pool = local.media_num_of_instances == 0 ? 0 : floor(local.media_num_of_instances / local.num_of_instance_pools)
  extra_instances         = local.media_num_of_instances % local.num_of_instance_pools

  instances_per_pool_list = [
    for i in range(local.num_of_instance_pools) :
    local.base_instances_per_pool + (i < local.extra_instances ? 1 : 0)
  ]

  num_of_pgs               = var.media_use_placement_group || var.app_use_placement_group ? 1 : 0
  media_cluster_pg_or_null = var.media_use_placement_group ? oci_cluster_placement_groups_cluster_placement_group.vlz_cluster_pg[0].id : null
  app_cluster_pg_or_null   = var.app_use_placement_group ? oci_cluster_placement_groups_cluster_placement_group.vlz_cluster_pg[0].id : null
  
}