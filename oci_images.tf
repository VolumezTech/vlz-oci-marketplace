variable "marketplace_source_images" {
  type = map(object({
    ocid                  = string
    is_pricing_associated = bool
    compatible_shapes     = set(string)
  }))
  default = {
    main_mktpl_image = {
      ocid                  = "ocid1.image.oc1..aaaaaaaae4o5zvaipl7xmspt3fhvzntb23vq42jszowjbso4kcl4lwzjy73a"
      is_pricing_associated = false
      compatible_shapes     = []
    }
  }
}