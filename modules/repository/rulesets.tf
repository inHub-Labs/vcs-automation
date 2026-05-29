resource "github_repository_ruleset" "this" {
  for_each = local.effective_branch_rules

  name        = "protect-${each.key}"
  repository  = github_repository.this.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = [each.value.ref_name]
      exclude = []
    }
  }

  rules {
    deletion                = each.value.rules.restrict_deletions
    non_fast_forward        = each.value.rules.block_force_pushes
    required_linear_history = each.value.rules.require_linear_history

    pull_request {
      required_approving_review_count   = each.value.rules.required_approvals
      dismiss_stale_reviews_on_push     = each.value.rules.dismiss_stale_pull_request_approvals
      require_code_owner_review         = each.value.rules.require_code_owner_review
      require_last_push_approval        = each.value.rules.require_approval_of_most_recent_push
      required_review_thread_resolution = each.value.rules.require_conversation_resolution
      allowed_merge_methods             = each.value.rules.allowed_merge_methods
    }

    dynamic "required_status_checks" {
      for_each = each.value.rules.require_status_checks_to_pass && length(each.value.rules.status_checks) > 0 ? [1] : []
      content {
        strict_required_status_checks_policy = true

        dynamic "required_check" {
          for_each = toset(each.value.rules.status_checks)
          content {
            context = required_check.value
          }
        }
      }
    }

  }

  depends_on = [
    github_branch.managed,
    github_repository_file.readme,
    github_repository_file.codeowners
  ]
}

resource "github_repository_ruleset" "branch_name_strategy_guard" {
  for_each = local.has_branch_strategy ? { enabled = true } : {}

  name        = "branch-name-strategy-guard"
  repository  = github_repository.this.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~ALL"]
      exclude = local.allowed_ref_patterns
    }
  }

  rules {
    creation = true
    update   = true
    deletion = true
  }
}
