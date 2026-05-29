locals {
  team_access = {
    for assignment in var.team_access :
    lower(trimspace(assignment.team_slug)) => {
      team_slug  = lower(trimspace(assignment.team_slug))
      permission = lower(trimspace(try(assignment.permission, "pull")))
    }
  }

  ignore_team_access = {
    for assignment in var.ignore_team_access :
    lower(trimspace(assignment.team_slug)) => {
      team_slug = lower(trimspace(assignment.team_slug))
    }
  }
}

resource "github_repository_collaborators" "this" {
  repository = github_repository.this.name

  dynamic "team" {
    for_each = local.team_access
    content {
      team_id    = team.value.team_slug
      permission = team.value.permission
    }
  }

  dynamic "ignore_team" {
    for_each = local.ignore_team_access
    content {
      team_id = ignore_team.value.team_slug
    }
  }
}
