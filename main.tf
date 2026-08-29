resource "random_password" "this" {
  for_each = {
    for name, config in var.secrets :
    name => config
    if config.generate
  }

  length  = each.value.length
  special = each.value.special
}

resource "google_secret_manager_secret" "this" {
  for_each = var.secrets

  project   = var.project_id
  secret_id = each.key

  replication {
    auto {}
  }

  labels = var.labels
}

resource "google_secret_manager_secret_version" "this" {
  for_each = var.secrets

  secret = google_secret_manager_secret.this[each.key].id

  secret_data = (
    each.value.generate
    ? random_password.this[each.key].result
    : each.value.value
  )
}