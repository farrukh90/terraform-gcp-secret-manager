# Usage

```hcl
module "secret" {
  source = "farrukh90/secret-manager/gcp"
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
