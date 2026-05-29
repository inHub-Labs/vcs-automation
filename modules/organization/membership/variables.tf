variable "username" {
  description = "GitHub username to add to the organization."
  type        = string

  validation {
    condition     = length(trimspace(var.username)) > 0
    error_message = "Username must not be empty."
  }
}

variable "role" {
  description = "Organization role: 'member' (default) or 'admin' (org owner)."
  type        = string
  default     = "member"

  validation {
    condition     = contains(["member", "admin"], var.role)
    error_message = "Role must be 'member' or 'admin'."
  }
}