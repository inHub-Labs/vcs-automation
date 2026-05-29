variable "github_organization" {
  description = "GitHub organization name where repositories will be managed."
  type        = string
}

variable "organization_members" {
  description = "Organization members to manage."
  type = list(object({
    username = string
    role     = optional(string, "member")
  }))
  default = []

  validation {
    condition = alltrue([
      for member in var.organization_members :
      length(trimspace(member.username)) > 0
    ])
    error_message = "Organization member usernames must not be empty."
  }

  validation {
    condition = alltrue([
      for member in var.organization_members :
      contains(["member", "admin"], lower(trimspace(try(member.role, "member"))))
    ])
    error_message = "Organization member roles must be either 'member' or 'admin'."
  }
}

# variable "organization_settings" {
#   description = "Organization settings to manage when the org settings module is enabled."
#   type = object({
#     billing_email                                                = optional(string)
#     has_organization_projects                                    = optional(bool)
#     has_repository_projects                                      = optional(bool)
#     default_repository_permission                                = optional(string)
#     members_can_create_repositories                              = optional(bool)
#     members_can_create_public_repositories                       = optional(bool)
#     members_can_create_private_repositories                      = optional(bool)
#     members_can_create_internal_repositories                     = optional(bool)
#     members_can_create_pages                                     = optional(bool)
#     members_can_create_public_pages                              = optional(bool)
#     members_can_create_private_pages                             = optional(bool)
#     members_can_fork_private_repositories                        = optional(bool)
#     web_commit_signoff_required                                  = optional(bool)
#     advanced_security_enabled_for_new_repositories               = optional(bool)
#     dependabot_alerts_enabled_for_new_repositories               = optional(bool)
#     dependabot_security_updates_enabled_for_new_repositories     = optional(bool)
#     dependency_graph_enabled_for_new_repositories                = optional(bool)
#     secret_scanning_enabled_for_new_repositories                 = optional(bool)
#     secret_scanning_push_protection_enabled_for_new_repositories = optional(bool)
#   })
#   default = {}
#
#   validation {
#     condition = (
#       try(var.organization_settings.default_repository_permission, null) == null ||
#       contains(
#         ["read", "write", "admin", "none"],
#         lower(trimspace(var.organization_settings.default_repository_permission))
#       )
#     )
#     error_message = "organization_settings.default_repository_permission must be one of: read, write, admin, none."
#   }
# }

variable "role_assignment" {
  description = "Organization role assignments keyed by role alias to team slug lists."
  type        = map(list(string))
  default     = {}

  validation {
    condition = alltrue([
      for role_key in keys(var.role_assignment) :
      contains([
        "pull",
        "push",
        "triage",
        "maintain",
        "admin",
        "cicdadmin",
        "securitymanager",
        "appmanager"
      ], lower(trimspace(role_key)))
    ])
    error_message = "role_assignment keys must be one of: pull, push, triage, maintain, admin, cicdadmin, securitymanager, appmanager."
  }

  validation {
    condition = alltrue(flatten([
      for principals in values(var.role_assignment) : [
        for team_slug in principals :
        length(trimspace(team_slug)) > 0
      ]
    ]))
    error_message = "role_assignment values must contain non-empty team slugs."
  }
}

variable "teams" {
  description = "GitHub teams to manage, including memberships."
  type = list(object({
    name        = string
    description = optional(string)
    privacy     = optional(string, "closed")
    members = optional(list(object({
      username = string
      role     = optional(string, "member")
    })), [])
  }))
  default = []

  validation {
    condition = alltrue([
      for team in var.teams :
      length(trimspace(team.name)) > 0
    ])
    error_message = "Team names must not be empty."
  }

  validation {
    condition = alltrue([
      for team in var.teams :
      can(regex("^[a-z0-9-]+$", trimspace(team.name)))
    ])
    error_message = "Team names must use slug format directly: lowercase letters, numbers, and hyphens only."
  }

  validation {
    condition = alltrue([
      for team in var.teams :
      contains(["closed", "secret"], lower(trimspace(try(team.privacy, "closed"))))
    ])
    error_message = "Team privacy must be either 'closed' or 'secret'."
  }

  validation {
    condition = alltrue(flatten([
      for team in var.teams : [
        for member in try(team.members, []) :
        length(trimspace(member.username)) > 0
      ]
    ]))
    error_message = "Team member username must not be empty."
  }

  validation {
    condition = alltrue(flatten([
      for team in var.teams : [
        for member in try(team.members, []) :
        contains(["member", "maintainer"], lower(trimspace(try(member.role, "member"))))
      ]
    ]))
    error_message = "Team member roles must be either 'member' or 'maintainer'."
  }
}


