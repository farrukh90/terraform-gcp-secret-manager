variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "name" {
  description = "Name of the Google Secret Manager secret"
  type        = string
}

variable "secrets" {
  description = "Values stored inside the secret"

  type = map(object({
    value    = optional(string)
    generate = optional(bool, false)
    length   = optional(number, 24)
    special  = optional(bool, false)
  }))

  validation {
    condition = alltrue([
      for secret in values(var.secrets) :
      secret.generate || secret.value != null
    ])

    error_message = "Each secret must either have a value or generate = true."
  }
}

variable "labels" {
  description = "Labels applied to managed resources"
  type        = map(string)
  default     = {}
}

variable "create_kubernetes_secret" {
  description = "Whether to create a Kubernetes Secret"
  type        = bool
  default     = false
}

variable "kubernetes_namespace" {
  description = "Namespace where the Kubernetes Secret will be created"
  type        = string
  default     = null
}

variable "kubernetes_secret_name" {
  description = "Name of the Kubernetes Secret"
  type        = string
  default     = null
}

variable "kubernetes_secret_keys" {
  description = "Mapping between secret fields and Kubernetes Secret keys"
  type        = map(string)
  default     = {}
}
