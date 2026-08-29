output "secret_ids" {
  description = "Map of Secret Manager secret IDs"

  value = {
    for name, secret in google_secret_manager_secret.this :
    name => secret.secret_id
  }
}

output "secret_names" {
  description = "Map of full Secret Manager resource names"

  value = {
    for name, secret in google_secret_manager_secret.this :
    name => secret.id
  }
}

output "secret_versions" {
  description = "Map of created Secret Manager secret versions"

  value = {
    for name, version in google_secret_manager_secret_version.this :
    name => version.name
  }
}