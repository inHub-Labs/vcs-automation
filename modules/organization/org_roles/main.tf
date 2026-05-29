resource "terraform_data" "validate_assignments" {
  count = length(var.team_assignments) > 0 ? 1 : 0

  lifecycle {
    precondition {
      condition     = length(local.unknown_role_keys) == 0
      error_message = "Unknown organization role name(s) in role_assignment variable: ${join(", ", sort(tolist(local.unknown_role_keys)))}"
    }
  }
}

resource "github_organization_role_team" "assignments" {
  for_each = local.normalized_team_assignments

  team_slug = each.value.team_slug
  role_id   = local.available_role_ids_by_key[each.value.role_key]

  depends_on = [terraform_data.validate_assignments]
}
