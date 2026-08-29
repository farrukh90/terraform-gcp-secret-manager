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

variable "password_length" {
  description = "Length of the generated password"
  type        = number
  default     = 24
}

variable "special" {
  description = "Whether to include special characters in the password"
  type        = bool
  default     = false
}

variable "labels" {
  description = "Labels to apply to the secret"
  type        = map(string)
  default     = {}
}