variable "billing_email" {
  description = "Billing email address for the organization."
  type        = string
  default     = null
}

variable "has_organization_projects" {
  type    = bool
  default = true
}

variable "has_repository_projects" {
  type    = bool
  default = true
}

variable "default_repository_permission" {
  type    = string
  default = "read"
}

variable "members_can_create_repositories" {
  type    = bool
  default = false
}

variable "members_can_create_public_repositories" {
  type    = bool
  default = null
}

variable "members_can_create_private_repositories" {
  type    = bool
  default = null
}

variable "members_can_create_internal_repositories" {
  type    = bool
  default = null
}

variable "members_can_create_pages" {
  type    = bool
  default = null
}

variable "members_can_create_public_pages" {
  type    = bool
  default = null
}

variable "members_can_create_private_pages" {
  type    = bool
  default = null
}

variable "members_can_fork_private_repositories" {
  type    = bool
  default = false
}

variable "web_commit_signoff_required" {
  type    = bool
  default = null
}

variable "advanced_security_enabled_for_new_repositories" {
  type    = bool
  default = null
}

variable "dependabot_alerts_enabled_for_new_repositories" {
  type    = bool
  default = null
}

variable "dependabot_security_updates_enabled_for_new_repositories" {
  type    = bool
  default = null
}

variable "dependency_graph_enabled_for_new_repositories" {
  type    = bool
  default = null
}

variable "secret_scanning_enabled_for_new_repositories" {
  type    = bool
  default = null
}

variable "secret_scanning_push_protection_enabled_for_new_repositories" {
  type    = bool
  default = null
}
