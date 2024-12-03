variable "marketplace_source_images" {
  type = map(object({
    ocid                  = string
    is_pricing_associated = bool
    compatible_shapes     = set(string)
  }))
  default = {
    main_mktpl_image = {
      ocid                  = "ocid1.image.oc1.iad.aaaaaaaahpxkae72yjmwf4z277z2kydw2s4snn2tafychp2n2jx2yqmyjl3q"
      is_pricing_associated = false
      compatible_shapes     = []
    }
  }
}