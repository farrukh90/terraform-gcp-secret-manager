variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "secrets" {
  description = "Secrets to create in Google Secret Manager"

  type = map(object({
    value    = optional(string)
    generate = optional(bool, false)
    length   = optional(number, 24)
    special  = optional(bool, false)
  }))
}

variable "labels" {
  description = "Labels to apply to the secrets"
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "name to apply to the secrets"
  type        = map(string)
  default     = {}
}
