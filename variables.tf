variable "email" {
  type        = string
  description = "Email address of the user"

}

variable "password" {
  type        = string
  description = "Password of the user"

}

variable "public_ssh_key" {
  default = ""
}

variable "generate_public_ssh_key" {
  default = true
}

variable "region" {
  type = string
  # default = "us-ashburn-1"
}

variable "availability_domain_name" {
  type        = string
  description = "Availability Domain Number"
}

variable "ad_number" {
  type        = number
  description = "Availability Domain Number"
  default     = 1

}

variable "fault_domains" {
  type        = list(string)
  description = "Fault Domains"
  default     = ["FAULT-DOMAIN-1", "FAULT-DOMAIN-2", "FAULT-DOMAIN-3"]
}

variable "subnet_cidr_block_list" {
  type    = list(string)
  default = ["10.1.20.0/24"]
}

variable "tenancy_ocid" {
  type        = string
  description = "value of the tenancy OCID"
}

variable "compartment_ocid" {
  type        = string
  description = "value of the compartment OCID"
}

variable "vlz_s3_path_to_conn" {
  type        = string
  description = "S3 Path to Connector"
  default     = "https://signup.volumez.com/oci_poc_14/ubuntu"
}

variable "vlz_rest_apigw" {
  type        = string
  description = "VLZ REST API Gateway"
  default     = "https://oci.api.volumez.com"
}


### Envs Sizes ###
variable "env_size" {
  type    = string
  default = "Small"
  validation {
    condition     = contains(["Small", "Medium", "Large"], var.env_size)
    error_message = "Invalid env_size. Must be one of Small, Medium, Large"
  }
}

### Media ###

variable "media_image_id" {
  type        = string
  description = "Image OCID"
  default     = "ocid1.image.oc1..aaaaaaaae4o5zvaipl7xmspt3fhvzntb23vq42jszowjbso4kcl4lwzjy73a"
}

variable "media_shape" {
  type        = string
  description = "Media Shape"
  default     = "VM.DenseIO.E5.Flex"
}

variable "media_memory_in_gbs" {
  type        = number
  description = "Memory in GBs"
  default     = 32
}

variable "media_num_of_ocpus" {
  type        = number
  description = "Memory in GBs"
  default     = 8
}

variable "media_ignore_cpu_mem_req" {
  type        = bool
  description = "Ignore CPU and Memory requirements"
  default     = false
}

variable "media_num_of_instances" {
  type        = number
  description = "Number of instances to be created"
  default     = 2
}

variable "media_use_placement_group" {
  type        = bool
  description = "Use Cluster Placement Group or not"
  default     = false
}

### App ###

variable "app_image_id" {
  type        = string
  description = "Image OCID"
  default     = "ocid1.image.oc1..aaaaaaaae4o5zvaipl7xmspt3fhvzntb23vq42jszowjbso4kcl4lwzjy73a"
}

variable "app_shape" {
  type        = string
  description = "Media Shape"
  default     = "VM.Standard.E5.Flex"
}

variable "app_memory_in_gbs" {
  type        = number
  description = "Memory in GBs"
  default     = 64
}

variable "app_num_of_ocpus" {
  type        = number
  description = "Memory in GBs"
  default     = 20
}

variable "app_ignore_cpu_mem_req" {
  type        = bool
  description = "Ignore CPU and Memory requirements"
  default     = false
}

variable "app_num_of_instances" {
  type        = number
  description = "Number of instances to be created"
  default     = 2
}
variable "app_use_placement_group" {
  type        = bool
  description = "Use Cluster Placement Group or not"
  default     = false
}

### Postgres ###
variable "postgres_version" {
  type        = string
  description = "Postgres Version"
  default     = "13"
  validation {
    condition     = contains(["13", "14", "15", "16"], var.postgres_version)
    error_message = "Invalid Postgres Version. Must be one of 13, 14, 15, 16"
  }

}