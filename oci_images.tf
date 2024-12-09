variable "marketplace_source_images" {
  type = map(object({
    ocid                  = string
    is_pricing_associated = bool
    compatible_shapes     = set(string)
  }))
  default = {
    main_mktpl_image = {
      ocid                  = "ocid1.image.oc1.iad.aaaaaaaasr6rkcl24zzmecvinvqxizgyqhlgyvw6ckzudknav62bxut7jaxq"
      is_pricing_associated = false
      compatible_shapes     = []
    }
  }
}