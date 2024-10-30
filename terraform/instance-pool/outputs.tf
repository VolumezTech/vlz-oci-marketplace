output "tls_private_key" {
  value     = var.generate_public_ssh_key ? tls_private_key.public_private_key_pair.private_key_pem : "Use your own private key"
  sensitive = true
}

output "public-ip-media-instances" {
  value = [{ for instance in data.oci_core_instance.media_instance : instance.display_name => instance.public_ip}]
}
output "public-ip-app-instances" {
  value = [{ for instance in data.oci_core_instance.app_instance : instance.display_name => instance.public_ip }]
}

output "media_instance_pool_name" {
  value = oci_core_instance_pool.media_instance_pool[0].display_name
}

output "media_instance_pool_id" {
  value = oci_core_instance_pool.media_instance_pool[0].id
}

output "app_instance_pool_name" {
  value = oci_core_instance_pool.app_instance_pool[0].display_name
}

output "app_instance_pool_id" {
  value = oci_core_instance_pool.app_instance_pool[0].id
}

output "oci_endpoint" {
  value = "https://oci.volumez.com/app#/pages/signin"
}

output "username" {
  value = var.email
}

output "password" {
  value = var.password
  sensitive = true
}

