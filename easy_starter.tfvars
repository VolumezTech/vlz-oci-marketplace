email    = ""
password = ""

### Networking ###
region                 = "us-ashburn-1"
ad_number              = 1
subnet_cidr_block_list = ["10.1.20.0/24"]
fault_domains          = ["FAULT-DOMAIN-1"]

### Credentials ###
tenancy_ocid        = ""
compartment_ocid    = ""
config_file_profile = "DEFAULT"

### VLZ ###
vlz_refresh_token   = ""
vlz_s3_path_to_conn = "https://signup.volumez.com/oci_poc_14/ubuntu"
vlz_rest_apigw      = "https://oci.api.volumez.com"

### Media ###
media_image_id            = "ocid1.image.oc1..aaaaaaaae4o5zvaipl7xmspt3fhvzntb23vq42jszowjbso4kcl4lwzjy73a"
media_num_of_instances    = 1
media_shape               = "VM.DenseIO.E4.Flex"
media_num_of_ocpus        = 8
media_memory_in_gbs       = 128
media_use_placement_group = false
media_ignore_cpu_mem_req  = false

### App ###
app_image_id            = "ocid1.image.oc1..aaaaaaaae4o5zvaipl7xmspt3fhvzntb23vq42jszowjbso4kcl4lwzjy73a"
app_num_of_instances    = 0
app_shape               = "VM.Standard.E5.Flex"
app_num_of_ocpus        = 8
app_memory_in_gbs       = 128
app_use_placement_group = false
app_ignore_cpu_mem_req  = false