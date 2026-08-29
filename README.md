# Usage
```
module "secrets" {
  source = "git::https://github.com/farrukh90/terraform-gcp-secret-manager.git?ref=v1.0.0"

  project_id = var.project_id

  secrets = {
    username = {
      value = "admin"
    }

    password = {
      generate = true
      length   = 24
    }
  }
}
```