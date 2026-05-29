output "assignments" {
  description = "Resolved organization role assignments"
  value = {
    for key, assignment in var.team_assignments : key => {
      team_slug = assignment.team_slug
      role_name = assignment.role_name
      role_id   = lookup(local.available_role_ids_by_key, assignment.role_key, null)
    }
  }
}
