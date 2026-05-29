variable "team_assignments" {
  description = "Organization role team assignments keyed by a deterministic string."
  type = map(object({
    role_key  = string
    role_name = string
    team_slug = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for assignment in values(var.team_assignments) : (
        length(trimspace(assignment.role_key)) > 0
        && length(trimspace(assignment.role_name)) > 0
        && length(trimspace(assignment.team_slug)) > 0
      )
    ])
    error_message = "Each team assignment must have non-empty role_key, role_name, and team_slug."
  }
}
