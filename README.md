# Usage
```
module "grafana_password" {
  source = "../../"

  project_id      = "terraform-project-504523"
  secret_id       = "grafana-admin-password"
  password_length = 24
  special         = false

  labels = {
    application = "grafana"
    managedby   = "terraform"
  }
}
```