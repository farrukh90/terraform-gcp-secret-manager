resource "random_password" "this" {
  for_each = {
    for name, config in var.secrets :
    name => config
    if try(config.generate, false)
  }

  length  = try(each.value.length, 24)
  special = try(each.value.special, false)
}


resource "google_secret_manager_secret" "this" {
  for_each = var.secrets

  project   = var.project_id
  secret_id = each.key

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "this" {
  for_each = var.secrets

  secret = google_secret_manager_secret.this[each.key].id

  secret_data = try(each.value.generate, false) ?
    random_password.this[each.key].result :
    each.value.value
}