resource "github_team" "this" {
  name        = var.name
  description = var.description
  privacy     = var.privacy
}

resource "github_team_membership" "members" {
  for_each = { for m in var.members : m.username => m }

  team_id  = github_team.this.id
  username = each.value.username
  role     = lower(trimspace(try(each.value.role, "member")))
}
