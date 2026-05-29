data "github_organization_roles" "available" {
  count = length(var.team_assignments) > 0 ? 1 : 0
}
