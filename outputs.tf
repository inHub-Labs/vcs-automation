output "repositories" {
  value = {
    for repo_name, repo_module in module.repositories : repo_name => {
      name     = repo_module.name
      html_url = repo_module.html_url
    }
  }
}

output "teams" {
  description = "All managed GitHub teams."
  value = {
    for team_name, team_module in module.teams : team_name => {
      name = team_module.name
      slug = team_module.slug
      id   = team_module.id
    }
  }
}

output "members" {
  description = "All managed org members and their roles."
  value = {
    for username, member_module in module.members : username => {
      username = member_module.username
      role     = member_module.role
    }
  }
}

# output "organization_role_assignments" {
#   description = "Managed organization role assignments."
#   value       = module.org_roles.assignments
# }
