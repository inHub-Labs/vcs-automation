locals {
  available_roles = (
    length(data.github_organization_roles.available) > 0
    ? data.github_organization_roles.available[0].roles
    : []
  )

  available_role_ids_by_key = {
    for role in local.available_roles :
    lower(trimspace(role.name)) => role.role_id
  }

  normalized_team_assignments = {
    for key, assignment in var.team_assignments :
    key => merge(assignment, {
      role_key  = lower(trimspace(assignment.role_key))
      team_slug = trimspace(assignment.team_slug)
    })
  }

  requested_role_keys = toset([
    for assignment in values(local.normalized_team_assignments) : assignment.role_key
  ])

  unknown_role_keys = setsubtract(
    local.requested_role_keys,
    toset(keys(local.available_role_ids_by_key))
  )
}
