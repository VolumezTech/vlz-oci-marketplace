email = "itay.ginor@volumez.com"
password = "Ginor2021#"

### Networking ###
region                 = "us-phoenix-1"
ad_number              = 1
subnet_cidr_block_list = ["10.1.20.0/24"]
fault_domains          = ["FAULT-DOMAIN-1"]

### Credentials ###
tenancy_ocid        = "ocid1.tenancy.oc1..aaaaaaaaij7gdgmcldaneftxyrhxiwpnaecvenjb42423cxhxmewlf65ca2q"
compartment_ocid    = "ocid1.tenancy.oc1..aaaaaaaaij7gdgmcldaneftxyrhxiwpnaecvenjb42423cxhxmewlf65ca2q"
config_file_profile = "DEFAULT"

### VLZ ###
vlz_refresh_token   = "eyJjdHkiOiJKV1QiLCJlbmMiOiJBMjU2R0NNIiwiYWxnIjoiUlNBLU9BRVAifQ.PEUbfWkJ6kHeUkK25C4uSXjGl_p3XmH5Zys9se2UJZiWYyAqPNSV_qpkfzkd83J9ITjCf-mquUM9pPmD-XqIIauPX3iTrcz0GnE5sTKsLZALLsG78OX0lGWe2lYIBJ_8sYybvCo4cPknJBouiR5uWiRmvwYYzjSEXdd7vjJptD4auOutk653kMEJJzknPnIBxG8_oHasvWm7q4QiD7BDxmN10vxG7pMRcgxNODqoCuZC8lnAZ_IwkBLM7qzWtum3LGA7ly6uLSeIcG7lxBhgvtg4hmQl-yuqz2BHE3kYsdPShVnv4ho3esEfhFxe08a8OK_ZHs_uJzqiCEgT1FME-g.N7CeDKUS1zq8Y_E_.BCObTR9o5ImNLQ3bTmG6hPF8QwNUxZrLb4Y5bjklBknj52H3RHwoi-kFWkXD8_6wENsY8O43Lrs7s4fzoTqyWpxMOSr3wakaeE8QjQ5wWQYBGNRf48MoDaRhXDn4xAWN3CQyNhY6Hh6cZcveq8Qptq1dSXrrXd_N9ggixunejuvqJ_niZ5R581e8s7FBHYf4jYX62eBe5WVZgSESpnOPcyDFA-RrwEJoGUcOXfvw6RZzLD8lCsKp8qFjcsgtZv-ejtUSUBsecYGrtWZMuVQNuv4rhcvD97M5aEbdC6y-c0xsNUSgGJh5H9Mgx4VeFSLy28U46ArZZBH4yG5unbWsqFdN8vunSTvhY_c5R7Bn8c1UIuob-NmeWxetONG1Z20vJgBvgZSwQZir8RmVGTFr90pYwxrpzxkFjSwhlP8W2PnH3zub-BLFLIsvhXOs4xJ3RMj93nLhoJZhlz9x0Bt-ovg9e3f32qki4cq0dngqbsCucV3f432OkB-_bXCy2C96O5pYjY_KwBHC_U5s8YF7_r7jvUq7DmS25d4ycozpfHbKaoVkYGtfZDlObv3aZopcu6xrwwpwa0yLN7pf7YuUAr6A3HEWou1eNB_DBgZnT5indGWWSTTrSHLPZYRM00vts2ZL7t_iTHWtibjxlBoEdBYHxkX-wLNNIEg-5pIqdqE9zyd3ttJdRT0ldKwp3xJsqbT_6jV8TnbGz_inf9xGSBVxtWMTehA8DABOmQWeWwWo05CmVVujKhL3jilXtibU1tqYrMM9reVectqUz-HMQEddh9a-OglQ0Ylu7j_dliJDhbo0a1PFCoxSGUjfwhkwhPAh6o-WjQUJKKqArw-MkkpVw23zNi6FE6AMxHP430RNb3aM2PmezxkkOJWTeMRBO6RgaDUbm1gVwDRvkOHW9iOzcmVJ8UEdWcVMbrEs8mpkTXovnUW_1B50UPNlWN6I7IEW1psS9bRlatFpMcbyEnEqAYZECIiftmLz4e621D-3rVLgZqUEak32V-mBcBSUBixpoHiED1ymI8P3q9lGw6hFaCqVnrxQcZYC0HTFw_zl-iPyHGk6ELWpdTvXPvwQObGBXSvugOsyKtRtk1kJUdM2hiWQjj8TuH6XJ8jv_VFBiS4ryrCBS3JaY0V2msPgRhIV-EqFR2T6N2LuWq8DzV2OSeCA1C8xABon2ndYnHGsRa9vriFrgj8rfWJHgKR38va4VqtL6uXZE-as62xRUxyIMKssTy9W1jKNIgRC_XuydOmrIc2zioBmKtUr93djHSMplVe3i10oX6uyWzazKfbhSpNzc4l9R0a-GmsvNaajpFE1_cFuQJEH38o3Ng.LIL2uZ6kHRiWaKKazQr9eQ"
vlz_s3_path_to_conn = "https://signup.volumez.com/oci_poc_14/ubuntu"
vlz_rest_apigw      = "https://oci.api.volumez.com"

### Media ###
media_image_id            = "ocid1.image.oc1.phx.aaaaaaaajxeqzy3z5qwcwtksj76ymu5gxt24qbv22r7lzukux7dbfugdwyka"
media_num_of_instances    = 1
media_shape               = "VM.DenseIO.E4.Flex"
media_num_of_ocpus        = 8
media_memory_in_gbs       = 128
media_use_placement_group = false
media_ignore_cpu_mem_req  = false

### App ###
app_image_id            = "ocid1.image.oc1.phx.aaaaaaaajxeqzy3z5qwcwtksj76ymu5gxt24qbv22r7lzukux7dbfugdwyka"
app_num_of_instances    = 0
app_shape               = "VM.Standard.E5.Flex"
app_num_of_ocpus        = 8
app_memory_in_gbs       = 128
app_use_placement_group = false
app_ignore_cpu_mem_req  = false