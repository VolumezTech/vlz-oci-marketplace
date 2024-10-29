output "tls_private_key" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}
output "public-ip-media-instance-pool" {
  value = { for instance in data.oci_core_instance.media_instance : instance.id => instance.public_ip}
}
output "public-ip-app-instance-pool" {
  value = { for instance in data.oci_core_instance.app_instance : instance.id => instance.public_ip }
}

output "oci_endpoint" {
  value = var.vlz_rest_apigw
}