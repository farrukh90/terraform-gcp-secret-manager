resource "random_password" "this" {
  length  = 24
  special = false
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

  secret_data = jsonencode({
    username = "admin"
    password = random_password.this.result
  })
}