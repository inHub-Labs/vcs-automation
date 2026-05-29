resource "github_membership" "this" {
  username = var.username
  role     = var.role
}