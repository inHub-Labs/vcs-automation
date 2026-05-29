variable "name" {
  description = "Team name"
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "Team name must not be empty."
  }
}

variable "description" {
  description = "Team description"
  type        = string
  default     = ""
}

variable "privacy" {
  description = "Team visibility: 'closed' or 'secret'."
  type        = string
  default     = "closed"

  validation {
    condition     = contains(["closed", "secret"], var.privacy)
    error_message = "Team privacy must be 'closed' or 'secret'."
  }
}

variable "members" {
  description = "List of org members to add to this team."
  type = list(object({
    username = string
    role     = optional(string, "member")
  }))
  default = []

  validation {
    condition = alltrue([
      for m in var.members : contains(["maintainer", "member"], lower(trimspace(try(m.role, "member"))))
    ])
    error_message = "Each member role must be 'maintainer' or 'member'."
  }

  validation {
    condition = alltrue([
      for m in var.members : length(trimspace(m.username)) > 0
    ])
    error_message = "Member usernames must not be empty strings."
  }
}
