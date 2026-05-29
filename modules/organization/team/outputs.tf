output "id" {
  description = "Numeric ID of the GitHub team (used for cross-references)."
  value       = github_team.this.id
}

output "name" {
  description = "Team display name."
  value       = github_team.this.name
}

output "slug" {
  description = "URL-safe slug GitHub assigns to the team."
  value       = github_team.this.slug
}
