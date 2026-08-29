variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "secret_id" {
  description = "Google Secret Manager secret name"
  type        = string
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