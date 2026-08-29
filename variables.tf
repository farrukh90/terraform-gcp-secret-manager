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
}

variable "labels" {
  description = "Labels applied to the secret"
  type        = map(string)
  default     = {}
}
