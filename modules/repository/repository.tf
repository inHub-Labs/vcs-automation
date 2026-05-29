resource "github_repository" "this" {
  name         = var.name
  description  = var.description
  homepage_url = "https://github.com/inHub-Labs/vcs-automation"
  visibility   = var.visibility
  topics       = var.topics
  auto_init    = true

  has_issues                  = var.has_issues
  has_discussions             = var.has_discussions
  has_projects                = var.has_projects
  has_wiki                    = var.has_wiki
  allow_merge_commit          = var.allow_merge_commit
  allow_squash_merge          = var.allow_squash_merge
  allow_rebase_merge          = var.allow_rebase_merge
  allow_auto_merge            = var.allow_auto_merge
  allow_forking               = var.allow_forking
  squash_merge_commit_title   = var.squash_merge_commit_title
  squash_merge_commit_message = var.squash_merge_commit_message
  merge_commit_title          = var.merge_commit_title
  merge_commit_message        = var.merge_commit_message
  delete_branch_on_merge      = var.delete_branch_on_merge
  web_commit_signoff_required = var.web_commit_signoff_required
  archived                    = var.archived
  archive_on_destroy          = var.archive_on_destroy
  vulnerability_alerts        = var.vulnerability_alerts
  allow_update_branch         = var.allow_update_branch

  lifecycle {
    precondition {
      condition     = !local.has_branch_strategy || length(local.invalid_configurable_keys) == 0
      error_message = "strategy_configurable keys must match protected branches for the selected strategy. Invalid keys: ${join(", ", local.invalid_configurable_keys)}"
    }
  }
}
