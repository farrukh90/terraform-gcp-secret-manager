output "secret_id" {
  description = "Google Secret Manager secret ID"
  value       = google_secret_manager_secret.this.secret_id
}

output "secret_name" {
  description = "Full Google Secret Manager resource name"
  value       = google_secret_manager_secret.this.id
}

output "secret_version" {
  description = "Google Secret Manager secret version"
  value       = google_secret_manager_secret_version.this.name
}

output "kubernetes_secret_name" {
  description = "Name of the Kubernetes Secret"
  value = var.create_kubernetes_secret ? (
    kubernetes_secret_v1.this[0].metadata[0].name
  ) : null
}