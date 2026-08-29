# Usage

This module creates a single Google Secret Manager secret containing multiple values as a JSON object.

It can also optionally create a Kubernetes Secret containing the same values.

## Google Secret Manager + Kubernetes Secret

The following example creates:

* One Google Secret Manager secret named `application`
* A static username
* A generated 24-character password
* One Kubernetes Secret named `application-credentials`
* Kubernetes keys mapped to `username` and `password`

```hcl
module "application-secrets" {
  source = "farrukh90/secret-manager/gcp"

  project_id = var.project_id
  name       = "application"

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
    application = "application"
    managedby   = "terraform"
  }

  create_kubernetes_secret = true
  kubernetes_namespace     = "application"
  kubernetes_secret_name   = "application-credentials"

  kubernetes_secret_keys = {
    username = "username"
    password = "password"
  }
}
```

## Google Secret Manager

The module creates one Google Secret Manager secret:

```text
application
```

The latest secret version contains a JSON object similar to:

```json
{
  "username": "admin",
  "password": "<generated-password>"
}
```

All values defined under `secrets` are stored together in a single Google Secret Manager secret.

The module is not limited to usernames and passwords. Any string-based values can be stored.

For example:

```hcl
secrets = {
  api_key = {
    generate = true
    length   = 40
  }

  environment = {
    value = "production"
  }

  database_user = {
    value = "appuser"
  }

  database_password = {
    generate = true
    length   = 32
  }
}
```

This produces JSON similar to:

```json
{
  "api_key": "<generated-value>",
  "environment": "production",
  "database_user": "appuser",
  "database_password": "<generated-value>"
}
```

## Kubernetes Secret

Kubernetes Secret creation is optional.

Enable it with:

```hcl
create_kubernetes_secret = true
```

When enabled, provide the Kubernetes namespace:

```hcl
kubernetes_namespace = "application"
```

You can also specify the Kubernetes Secret name:

```hcl
kubernetes_secret_name = "application-credentials"
```

If `kubernetes_secret_name` is not provided, the module uses the value of `name`.

For example:

```hcl
name = "application"

create_kubernetes_secret = true
kubernetes_namespace     = "application"
```

will create a Kubernetes Secret named:

```text
application
```

inside the `application` namespace.

## Kubernetes Secret Key Mapping

By default, the Kubernetes Secret uses the same key names defined in `secrets`.

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
```

will create Kubernetes keys:

```text
username
password
```

You can override these names with `kubernetes_secret_keys`.

```hcl
kubernetes_secret_keys = {
  username = "application-user"
  password = "application-password"
}
```

The Google Secret Manager secret will still contain:

```json
{
  "username": "admin",
  "password": "<generated-password>"
}
```

while the Kubernetes Secret will contain:

```text
application-user
application-password
```

This allows the module to work with applications that require specific Kubernetes Secret key names.

## Google Secret Manager Only

To create only the Google Secret Manager secret:

```hcl
module "application-secrets" {
  source = "farrukh90/secret-manager/gcp"

  project_id = var.project_id
  name       = "application"

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
    application = "application"
    managedby   = "terraform"
  }

  create_kubernetes_secret = false
}
```

Because `create_kubernetes_secret` defaults to `false`, it can also be omitted:

```hcl
module "application-secrets" {
  source = "farrukh90/secret-manager/gcp"

  project_id = var.project_id
  name       = "application"

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
└── application
    ├── username
    └── password
```

## Read and Decode the Google Secret

If the Kubernetes Secret is not created by the module and the secret needs to be consumed elsewhere in Terraform, it can be read using the Google Secret Manager data source.

```hcl
data "google_secret_manager_secret_version" "application" {
  secret = module.application-secrets.secret_id

  depends_on = [
    module.application-secrets
  ]
}
```

Because the secret is stored as JSON, use `jsondecode()` to access individual values:

```hcl
locals {
  application_credentials = jsondecode(
    data.google_secret_manager_secret_version.application.secret_data
  )
}
```

Individual values can then be referenced with:

```hcl
local.application_credentials.username
local.application_credentials.password
```

If the module uses `count`, reference the module instance accordingly:

```hcl
module "application-secrets" {
  source = "farrukh90/secret-manager/gcp"

  count = var.application_enabled ? 1 : 0

  project_id = var.project_id
  name       = "application"

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

Then read the secret with:

```hcl
data "google_secret_manager_secret_version" "application" {
  count = var.application_enabled ? 1 : 0

  secret = module.application-secrets[0].secret_id

  depends_on = [
    module.application-secrets
  ]
}
```

And decode it:

```hcl
locals {
  application_credentials = var.application_enabled ? jsondecode(
    data.google_secret_manager_secret_version.application[0].secret_data
  ) : {}
}
```

## Generated Values

Any secret field can be generated automatically.

```hcl
secrets = {
  password = {
    generate = true
  }
}
```

By default, generated values use:

```text
length  = 24
special = false
```

These values can be customized:

```hcl
secrets = {
  password = {
    generate = true
    length   = 32
    special  = true
  }

  api_key = {
    generate = true
    length   = 48
    special  = false
  }
}
```

## Static Values

Static values can be provided using `value`:

```hcl
secrets = {
  username = {
    value = "admin"
  }

  environment = {
    value = "production"
  }
}
```

Generated and static values can be mixed within the same secret.

```hcl
secrets = {
  username = {
    value = "admin"
  }

  password = {
    generate = true
  }

  environment = {
    value = "production"
  }
}
```

## Complete Example

```hcl
module "application-secrets" {
  source = "farrukh90/secret-manager/gcp"

  project_id = var.project_id
  name       = "application"

  secrets = {
    username = {
      value = "admin"
    }

    password = {
      generate = true
      length   = 24
      special  = false
    }

    api_key = {
      generate = true
      length   = 40
      special  = false
    }

    environment = {
      value = "production"
    }
  }

  labels = {
    application = "application"
    environment = "production"
    managedby   = "terraform"
  }

  create_kubernetes_secret = true
  kubernetes_namespace     = "application"
  kubernetes_secret_name   = "application-secrets"

  kubernetes_secret_keys = {
    username    = "username"
    password    = "password"
    api_key     = "api-key"
    environment = "environment"
  }
}
```

This creates:

```text
Google Secret Manager
└── application
    ├── username
    ├── password
    ├── api_key
    └── environment

Kubernetes
└── application/application-secrets
    ├── username
    ├── password
    ├── api-key
    └── environment
```

## Credential Flow

```text
Static Values
     |
     |
     +------------------+
                        |
Generated Values        |
     |                  |
     v                  v
random_password    Module Secret Data
                        |
              +---------+---------+
              |                   |
              v                   v
    Google Secret Manager    Kubernetes Secret
              |                   |
              v                   v
        JSON Secret         Application / Service
```

## Inputs

| Name                       | Description                                              | Type          | Default  |
| -------------------------- | -------------------------------------------------------- | ------------- | -------- |
| `project_id`               | GCP project ID                                           | `string`      | Required |
| `name`                     | Google Secret Manager secret name                        | `string`      | Required |
| `secrets`                  | Values to store inside the secret                        | `map(object)` | Required |
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
| `length`   | Generated value length     | `24`    |
| `special`  | Include special characters | `false` |

Example:

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

Each secret entry must either define a static `value` or set:

```hcl
generate = true
```

## Outputs

The module exposes information about created resources without intentionally outputting secret values.

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

The secret values themselves are intentionally not exposed as module outputs.

## Important

Generated and supplied secret values are stored in Terraform state because Terraform manages the secret data.

This applies to both:

```text
google_secret_manager_secret_version.secret_data
```

and Kubernetes Secret values managed through:

```text
kubernetes_secret_v1
```

Protect the Terraform state backend appropriately, restrict access to the state, and never commit local Terraform state files to Git.


## Usage with Helm

When `create_kubernetes_secret = true`, the module creates a Kubernetes Secret that can be consumed by a Helm chart.

For example:

```hcl
module "application-secrets" {
  source = "farrukh90/secret-manager/gcp"

  project_id = var.project_id
  name       = "application"

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

  create_kubernetes_secret = true
  kubernetes_namespace     = "application"
  kubernetes_secret_name   = "application-credentials"

  kubernetes_secret_keys = {
    username = "username"
    password = "password"
  }

  labels = {
    application = "application"
    managedby   = "terraform"
  }
}
```

This creates the Kubernetes Secret:

```text
application-credentials
├── username
└── password
```

A Helm chart can then reference that Secret.

### Example Helm Deployment

```hcl
module "application-helm" {
  source = "farrukh90/appdeploy/helm"

  name       = "application"
  namespace  = "application"
  chart      = "application"
  repository = "https://example.com/helm-charts"

  values = [<<EOF

existingSecret: application-credentials

secretKeys:
  username: username
  password: password

EOF
  ]

  depends_on = [
    module.application-secrets
  ]
}
```

The exact Helm values depend on the chart being deployed. Different charts may use names such as:

```yaml
existingSecret: application-credentials
```

or:

```yaml
auth:
  existingSecret: application-credentials
```

or:

```yaml
credentials:
  existingSecret: application-credentials
  usernameKey: username
  passwordKey: password
```

Always check the Helm chart's `values.yaml` to determine the expected secret configuration.

## Helm Chart with Custom Secret Keys

Some Helm charts require specific Kubernetes Secret key names.

For example, an application may expect:

```text
admin-user
admin-password
```

The module can map the generic Google Secret Manager keys to those Kubernetes keys:

```hcl
module "application-secrets" {
  source = "farrukh90/secret-manager/gcp"

  project_id = var.project_id
  name       = "application"

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

  create_kubernetes_secret = true
  kubernetes_namespace     = "application"
  kubernetes_secret_name   = "application-credentials"

  kubernetes_secret_keys = {
    username = "admin-user"
    password = "admin-password"
  }
}
```

The Google Secret Manager secret contains:

```json
{
  "username": "admin",
  "password": "<generated-password>"
}
```

while the Kubernetes Secret contains:

```text
application-credentials
├── admin-user
└── admin-password
```

The Helm chart can then reference those exact keys:

```yaml
admin:
  existingSecret: application-credentials
  userKey: admin-user
  passwordKey: admin-password
```

## Helm with Namespace Module

If the namespace is also managed by Terraform:

```hcl
module "application-ns" {
  source = "farrukh90/ns/kubernetes"

  name = "application"

  labels = {
    managedby = "terraform"
  }
}
```

The namespace output can be passed directly to the secret module:

```hcl
module "application-secrets" {
  source = "farrukh90/secret-manager/gcp"

  project_id = var.project_id
  name       = "application"

  secrets = {
    username = {
      value = "admin"
    }

    password = {
      generate = true
    }
  }

  create_kubernetes_secret = true
  kubernetes_namespace     = module.application-ns.name
  kubernetes_secret_name   = "application-credentials"

  kubernetes_secret_keys = {
    username = "username"
    password = "password"
  }

  depends_on = [
    module.application-ns
  ]
}
```

The Helm deployment can use the same namespace:

```hcl
module "application-helm" {
  source = "farrukh90/appdeploy/helm"

  name      = "application"
  namespace = module.application-ns.name

  chart      = "application"
  repository = "https://example.com/helm-charts"

  values = [<<EOF

existingSecret: application-credentials

EOF
  ]

  depends_on = [
    module.application-secrets
  ]
}
```

The resulting dependency flow is:

```text
Kubernetes Namespace
        |
        v
Secret Module
        |
        +-----------------------+
        |                       |
        v                       v
Google Secret Manager     Kubernetes Secret
                                  |
                                  v
                            Helm Deployment
                                  |
                                  v
                             Application
```

Using `depends_on = [module.application-secrets]` ensures the Kubernetes Secret exists before the Helm release is deployed.
