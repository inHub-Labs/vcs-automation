resource "github_branch_default" "this" {
  repository = github_repository.this.name
  branch     = local.default_branch
  rename     = local.default_branch != var.repository_init_branch

  depends_on = [github_branch.managed]
}

resource "github_branch" "managed" {
  for_each = local.branches_to_create

  repository    = github_repository.this.name
  branch        = each.key
  source_branch = var.repository_init_branch
}
