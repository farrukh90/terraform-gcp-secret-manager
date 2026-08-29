# Usage

This module creates a single Google Secret Manager secret containing multiple values as a JSON object.

For example, the configuration below creates one secret named `grafana` with a username and generated password.

```hcl
module "grafana-secrets" {
  source = "farrukh90/secret-manager/gcp"

  count = var.grafana ? 1 : 0

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

This creates one Google Secret Manager secret:

```text
grafana
```

The latest secret version contains JSON similar to:

```json
{
  "username": "admin",
  "password": "<generated-password>"
}
```

## Read the Secret

The secret can be read using the Google Secret Manager data source:

```hcl
data "google_secret_manager_secret_version" "grafana" {
  count = var.grafana ? 1 : 0

  project = var.project_id
  secret  = module.grafana-secrets[0].secret_id

  depends_on = [
    module.grafana-secrets
  ]
}
```

## Decode the JSON Secret

Because the secret value is stored as JSON, use `jsondecode()` to access individual values:

```hcl
locals {
  grafana_credentials = var.grafana ? jsondecode(
    data.google_secret_manager_secret_version.grafana[0].secret_data
  ) : {}
}
```

The values can then be referenced as:

```hcl
local.grafana_credentials.username
local.grafana_credentials.password
```

## Create a Kubernetes Secret

For Grafana, the decoded values can be placed into a Kubernetes Secret:

```hcl
resource "kubernetes_secret_v1" "grafana_admin" {
  count = var.grafana ? 1 : 0

  metadata {
    name      = "grafana-admin-credentials"
    namespace = module.grafana-ns[0].name
  }

  data = {
    "admin-user"     = local.grafana_credentials.username
    "admin-password" = local.grafana_credentials.password
  }

  type = "Opaque"
}
```

The Kubernetes Secret will contain:

```text
grafana-admin-credentials

admin-user
admin-password
```

## Configure Grafana

The Grafana Helm chart can use the Kubernetes Secret directly:

```yaml
admin:
  existingSecret: grafana-admin-credentials
  userKey: admin-user
  passwordKey: admin-password
```

The complete credential flow is:

```text
random_password
      |
      v
Google Secret Manager
      |
      +-- grafana
            |
            +-- username
            +-- password
                  |
                  v
             jsondecode()
                  |
                  v
Kubernetes Secret
      |
      +-- admin-user
      +-- admin-password
                  |
                  v
               Grafana
```

## Additional Example

The module can also be used for other applications:

```hcl
module "vault-secrets" {
  source = "farrukh90/secret-manager/gcp"

  project_id = var.project_id
  name       = "vault"

  secrets = {
    username = {
      value = "admin"
    }

    password = {
      generate = true
      length   = 32
      special  = true
    }
  }

  labels = {
    application = "vault"
    managedby   = "terraform"
  }
}
```

This creates a single Google Secret Manager secret named:

```text
vault
```

containing:

```json
{
  "username": "admin",
  "password": "<generated-password>"
}
```

## Outputs

The module exposes the Secret Manager secret information without outputting the secret value itself:

```hcl
output "secret_id" {
  description = "Secret Manager secret ID"
  value       = google_secret_manager_secret.this.secret_id
}

output "secret_name" {
  description = "Full Secret Manager resource name"
  value       = google_secret_manager_secret.this.id
}

output "secret_version" {
  description = "Secret version name"
  value       = google_secret_manager_secret_version.this.name
}
```

The secret value itself is intentionally not exposed as a module output.

## Important

Generated and supplied secret values are still stored in Terraform state because Terraform manages the `google_secret_manager_secret_version.secret_data` value.

Protect the Terraform state backend appropriately and avoid committing local state files to Git.
