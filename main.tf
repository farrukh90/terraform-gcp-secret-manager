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

  kubernetes_secret_data = {
    for name, value in local.secret_data :
    lookup(var.kubernetes_secret_keys, name, name) => value
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

resource "kubernetes_secret_v1" "this" {
  count = var.create_kubernetes_secret ? 1 : 0

  metadata {
    name = coalesce(
      var.kubernetes_secret_name,
      var.name
    )

    namespace = var.kubernetes_namespace

    labels = var.labels
  }

  data = local.kubernetes_secret_data

  type = "Opaque"

  lifecycle {
    precondition {
      condition     = var.kubernetes_namespace != null
      error_message = "kubernetes_namespace must be provided when create_kubernetes_secret is true."
    }
  }
}
