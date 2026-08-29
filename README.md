# Usage

```hcl
module "grafana-secrets" {
  source = "farrukh90/secret-manager/gcp"
  count  = var.grafana ? 1 : 0

  project_id = var.project_id
  name       = "grafana"

  secrets = {
    username = {
      value = "admin"
    }

    password = {
      generate = true
      length   = 24
      special  = false
    }
  }

  labels = {
    application = "grafana"
    managedby   = "terraform"
  }
}
```
