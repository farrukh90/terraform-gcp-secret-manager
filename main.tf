resource "random_password" "this" {
  for_each = {
    for name, config in var.secrets :
    name => config
    if config.generate
  }

  length  = each.value.length
  special = each.value.special
}

locals {
  secret_data = {
    for name, config in var.secrets :
    name => (
      config.generate
      ? random_password.this[name].result
      : config.value
    )
  }
}

resource "google_secret_manager_secret" "this" {
  project   = var.project_id
  secret_id = var.name

  replication {
    auto {}
  }

  labels = var.labels
}

resource "google_secret_manager_secret_version" "this" {
  secret = google_secret_manager_secret.this.id

  secret_data = jsonencode(local.secret_data)
}