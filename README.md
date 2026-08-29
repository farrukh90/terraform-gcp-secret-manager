# Usage

This module creates a single Google Secret Manager secret containing multiple values as a JSON object.

It can also optionally create a Kubernetes Secret containing the same values.

## Google Secret Manager + Kubernetes Secret

The following example creates:

* One Google Secret Manager secret named `grafana`
* A generated 24-character password
* One Kubernetes Secret named `grafana-admin-credentials`
* Kubernetes keys mapped to `admin-user` and `admin-password`

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

  create_kubernetes_secret = true
  kubernetes_namespace     = module.grafana-ns[0].name
  kubernetes_secret_name   = "grafana-admin-credentials"

  kubernetes_secret_keys = {
    username = "admin-user"
    password = "admin-password"
  }
}
```

## Google Secret Manager

The module creates one Google Secret Manager secret:

```text
grafana
```

The latest secret version contains a JSON object similar to:

```json
{
  "username": "admin",
  "password": "<generated-password>"
}
```

The username and password are stored together in a single Google Secret Manager secret.

## Kubernetes Secret

When:

```hcl
create_kubernetes_secret = true
```

the module also creates:

```text
grafana-admin-credentials
```

in the namespace specified by:

```hcl
kubernetes_namespace = module.grafana-ns[0].name
```

The `kubernetes_secret_keys` map controls how fields from the Google secret are named inside Kubernetes:

```hcl
kubernetes_secret_keys = {
  username = "admin-user"
  password = "admin-password"
}
```

This produces a Kubernetes Secret containing:

```text
grafana-admin-credentials
├── admin-user
└── admin-password
```

The values are populated automatically from the same data used to create the Google Secret Manager secret.

## Configure Grafana

The Grafana Helm chart can use the Kubernetes Secret directly:

```yaml
admin:
  existingSecret: grafana-admin-credentials
  userKey: admin-user
  passwordKey: admin-password
```

No Google Secret Manager data source or `jsondecode()` is required in the calling Terraform configuration when `create_kubernetes_secret` is enabled.

The complete flow is:

```text
                     random_password
                           |
                           v
                 +-------------------+
                 |   Module Values   |
                 +-------------------+
                    |             |
                    |             |
                    v             v
        Google Secret Manager   Kubernetes Secret
        +------------------+    +---------------------------+
        | grafana          |    | grafana-admin-credentials |
        |                  |    |                           |
        | username         |    | admin-user                |
        | password         |    | admin-password            |
        +------------------+    +---------------------------+
                                          |
                                          v
                                       Grafana
```

## Google Secret Manager Only

Kubernetes Secret creation is optional.

To create only the Google Secret Manager secret:

```hcl
module "grafana-secrets" {
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

  create_kubernetes_secret = false

  labels = {
    application = "grafana"
    managedby   = "terraform"
  }
}
```

`create_kubernetes_secret` defaults to `false`, so it can also be omitted:

```hcl
module "grafana-secrets" {
  source = "farrukh90/secret-manager/gcp"

  project_id = var.project_id
  name       = "grafana"

  secrets = {
    username = {
      value = "admin"
    }

    password = {
      generate = true
    }
  }
}
```

This creates only:

```text
Google Secret Manager
└── grafana
    ├── username
    └── password
```

## Read and Decode the Google Secret

If the Kubernetes Secret is not created by the module and the secret needs to be consumed elsewhere in Terraform, it can be read from Google Secret Manager.

```hcl
data "google_secret_manager_secret_version" "grafana" {
  secret = module.grafana-secrets.secret_id

  depends_on = [
    module.grafana-secrets
  ]
}
```

Because the secret is stored as JSON, decode it with `jsondecode()`:

```hcl
locals {
  grafana_credentials = jsondecode(
    data.google_secret_manager_secret_version.grafana.secret_data
  )
}
```

Individual values can then be accessed with:

```hcl
local.grafana_credentials.username
local.grafana_credentials.password
```

If the module uses `count`, reference the module instance accordingly:

```hcl
data "google_secret_manager_secret_version" "grafana" {
  count = var.grafana ? 1 : 0

  secret = module.grafana-secrets[0].secret_id

  depends_on = [
    module.grafana-secrets
  ]
}
```

Then:

```hcl
locals {
  grafana_credentials = var.grafana ? jsondecode(
    data.google_secret_manager_secret_version.grafana[0].secret_data
  ) : {}
}
```

## Custom Kubernetes Key Mapping

The names stored in Google Secret Manager do not need to match the names expected by an application.

For example:

```hcl
secrets = {
  username = {
    value = "admin"
  }

  password = {
    generate = true
  }
}

kubernetes_secret_keys = {
  username = "admin-user"
  password = "admin-password"
}
```

Google Secret Manager contains:

```json
{
  "username": "admin",
  "password": "<generated-password>"
}
```

while Kubernetes contains:

```text
admin-user
admin-password
```

This allows the module to work with applications that require specific Kubernetes Secret key names.

## Additional Example

The same module can be reused for other applications.

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

  create_kubernetes_secret = true
  kubernetes_namespace     = "vault"
  kubernetes_secret_name   = "vault-credentials"

  kubernetes_secret_keys = {
    username = "username"
    password = "password"
  }
}
```

This creates:

```text
Google Secret Manager
└── vault
    ├── username
    └── password

Kubernetes
└── vault/vault-credentials
    ├── username
    └── password
```

## Inputs

| Name                       | Description                                              | Type          | Default  |
| -------------------------- | -------------------------------------------------------- | ------------- | -------- |
| `project_id`               | GCP project ID                                           | `string`      | Required |
| `name`                     | Google Secret Manager secret name                        | `string`      | Required |
| `secrets`                  | Values to store in the secret                            | `map(object)` | Required |
| `labels`                   | Labels applied to managed resources                      | `map(string)` | `{}`     |
| `create_kubernetes_secret` | Whether to create a Kubernetes Secret                    | `bool`        | `false`  |
| `kubernetes_namespace`     | Namespace for the Kubernetes Secret                      | `string`      | `null`   |
| `kubernetes_secret_name`   | Name of the Kubernetes Secret                            | `string`      | `null`   |
| `kubernetes_secret_keys`   | Mapping between secret fields and Kubernetes Secret keys | `map(string)` | `{}`     |

Each entry in `secrets` supports:

| Attribute  | Description                | Default |
| ---------- | -------------------------- | ------- |
| `value`    | Static value to store      | `null`  |
| `generate` | Generate a random value    | `false` |
| `length`   | Generated password length  | `24`    |
| `special`  | Include special characters | `false` |

For example:

```hcl
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
```

## Outputs

The module exposes information about the created resources without intentionally outputting the secret values.

```hcl
output "secret_id" {
  description = "Google Secret Manager secret ID"
  value       = google_secret_manager_secret.this.secret_id
}

output "secret_name" {
  description = "Full Google Secret Manager resource name"
  value       = google_secret_manager_secret.this.id
}

output "secret_version" {
  description = "Google Secret Manager secret version"
  value       = google_secret_manager_secret_version.this.name
}

output "kubernetes_secret_name" {
  description = "Name of the Kubernetes Secret"

  value = var.create_kubernetes_secret ? (
    kubernetes_secret_v1.this[0].metadata[0].name
  ) : null
}
```

## Important

Generated passwords and supplied secret values are stored in Terraform state because Terraform manages the secret values.

This applies to both Google Secret Manager secret data and Kubernetes Secret data managed by Terraform.

Protect the Terraform state backend appropriately, enable suitable access controls, and never commit local Terraform state files to Git.
