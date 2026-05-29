output "username" {
  description = "GitHub username of the managed organization member."
  value       = github_membership.this.username
}

output "role" {
  description = "Role given in the organization ('member' or 'admin')."
  value       = github_membership.this.role
}