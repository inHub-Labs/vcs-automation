locals {
  has_branch_strategy = var.branch_strategy != null && length(trimspace(var.branch_strategy)) > 0
  branch_strategy     = local.has_branch_strategy ? lower(trimspace(var.branch_strategy)) : null

  branch_strategy_defaults = {
    github_flow = {
      default_branch     = "main"
      branches_to_create = []
      allowed_ref_patterns = [
        "refs/heads/main",
        "refs/heads/feature/*"
      ]
      protected_branches = {
        main = {
          ref_name = "refs/heads/main"
          rules = {
            require_pull_request_before_merging  = true
            required_approvals                   = 1
            dismiss_stale_pull_request_approvals = true
            require_conversation_resolution      = true
            require_status_checks_to_pass        = true
            status_checks                        = []
            block_force_pushes                   = true
            restrict_deletions                   = true
            require_linear_history               = false
            require_code_owner_review            = false
            require_approval_of_most_recent_push = false
            allowed_merge_methods                = ["squash"]
          }
        }
      }
    }
    simplified_gitflow = {
      default_branch     = "main"
      branches_to_create = ["develop"]
      allowed_ref_patterns = [
        "refs/heads/main",
        "refs/heads/develop",
        "refs/heads/feature/*",
        "refs/heads/hot-fix/*"
      ]
      protected_branches = {
        main = {
          ref_name = "refs/heads/main"
          rules = {
            require_pull_request_before_merging  = true
            required_approvals                   = 1
            dismiss_stale_pull_request_approvals = true
            require_conversation_resolution      = true
            require_status_checks_to_pass        = true
            status_checks                        = []
            block_force_pushes                   = true
            restrict_deletions                   = true
            require_linear_history               = false
            require_code_owner_review            = false
            require_approval_of_most_recent_push = false
            allowed_merge_methods                = ["squash"]
          }
        }
        develop = {
          ref_name = "refs/heads/develop"
          rules = {
            require_pull_request_before_merging  = true
            required_approvals                   = 1
            dismiss_stale_pull_request_approvals = true
            require_conversation_resolution      = true
            require_status_checks_to_pass        = true
            status_checks                        = []
            block_force_pushes                   = true
            restrict_deletions                   = false
            require_linear_history               = false
            require_code_owner_review            = false
            require_approval_of_most_recent_push = false
            allowed_merge_methods                = ["merge", "squash"]
          }
        }
      }
    }
    gitflow = {
      default_branch     = "main"
      branches_to_create = ["develop"]
      allowed_ref_patterns = [
        "refs/heads/main",
        "refs/heads/develop",
        "refs/heads/feature/*",
        "refs/heads/release/*",
        "refs/heads/hot-fix/*"
      ]
      protected_branches = {
        main = {
          ref_name = "refs/heads/main"
          rules = {
            require_pull_request_before_merging  = true
            required_approvals                   = 2
            dismiss_stale_pull_request_approvals = true
            require_conversation_resolution      = true
            require_status_checks_to_pass        = true
            status_checks                        = []
            block_force_pushes                   = true
            restrict_deletions                   = true
            require_linear_history               = false
            require_code_owner_review            = false
            require_approval_of_most_recent_push = false
            allowed_merge_methods                = ["merge", "squash"]
          }
        }
        develop = {
          ref_name = "refs/heads/develop"
          rules = {
            require_pull_request_before_merging  = true
            required_approvals                   = 1
            dismiss_stale_pull_request_approvals = true
            require_conversation_resolution      = true
            require_status_checks_to_pass        = true
            status_checks                        = []
            block_force_pushes                   = true
            restrict_deletions                   = false
            require_linear_history               = false
            require_code_owner_review            = false
            require_approval_of_most_recent_push = false
            allowed_merge_methods                = ["merge", "squash"]
          }
        }
        "release/*" = {
          ref_name = "refs/heads/release/*"
          rules = {
            require_pull_request_before_merging  = true
            required_approvals                   = 1
            dismiss_stale_pull_request_approvals = true
            require_conversation_resolution      = true
            require_status_checks_to_pass        = true
            status_checks                        = []
            block_force_pushes                   = true
            restrict_deletions                   = false
            require_linear_history               = false
            require_code_owner_review            = false
            require_approval_of_most_recent_push = false
            allowed_merge_methods                = ["merge"]
          }
        }
      }
    }
  }

  strategy_rules = local.has_branch_strategy ? local.branch_strategy_defaults[local.branch_strategy] : null

  default_branch = local.has_branch_strategy ? local.strategy_rules.default_branch : var.repository_init_branch

  branches_to_create = {
    for branch_name in(local.has_branch_strategy ? local.strategy_rules.branches_to_create : []) :
    branch_name => branch_name
  }

  allowed_ref_patterns = local.has_branch_strategy ? local.strategy_rules.allowed_ref_patterns : []

  protected_branch_keys = local.has_branch_strategy ? keys(local.strategy_rules.protected_branches) : []

  configurable_override_keys = distinct(flatten([
    keys(var.strategy_configurable.required_approvals),
    keys(var.strategy_configurable.status_checks),
    keys(var.strategy_configurable.require_linear_history),
    keys(var.strategy_configurable.require_code_owner_review),
    keys(var.strategy_configurable.require_approval_of_most_recent_push),
    keys(var.strategy_configurable.allowed_merge_methods)
  ]))

  invalid_configurable_keys = [
    for branch_key in local.configurable_override_keys :
    branch_key
    if local.has_branch_strategy && !contains(local.protected_branch_keys, branch_key)
  ]

  protected_ref_patterns = {
    for branch_key, branch_config in(local.has_branch_strategy ? local.strategy_rules.protected_branches : {}) :
    replace(replace(replace(replace(branch_key, "refs/heads/", ""), "*", "wildcard"), "/", "-"), ".", "-") => merge(branch_config, {
      branch_key = branch_key
    })
  }

  effective_branch_rules = {
    for rule_key, branch_cfg in local.protected_ref_patterns :
    rule_key => {
      branch_key = branch_cfg.branch_key
      ref_name   = branch_cfg.ref_name
      rules = merge(branch_cfg.rules, {
        required_approvals = lookup(
          var.strategy_configurable.required_approvals,
          branch_cfg.branch_key,
          branch_cfg.rules.required_approvals
        )
        status_checks = distinct(concat(
          branch_cfg.rules.status_checks,
          lookup(var.strategy_configurable.status_checks, branch_cfg.branch_key, [])
        ))
        require_linear_history = lookup(
          var.strategy_configurable.require_linear_history,
          branch_cfg.branch_key,
          branch_cfg.rules.require_linear_history
        )
        require_code_owner_review = lookup(
          var.strategy_configurable.require_code_owner_review,
          branch_cfg.branch_key,
          branch_cfg.rules.require_code_owner_review
        )
        require_approval_of_most_recent_push = lookup(
          var.strategy_configurable.require_approval_of_most_recent_push,
          branch_cfg.branch_key,
          branch_cfg.rules.require_approval_of_most_recent_push
        )
        allowed_merge_methods = [
          for method in lookup(
            var.strategy_configurable.allowed_merge_methods,
            branch_cfg.branch_key,
            branch_cfg.rules.allowed_merge_methods
          ) : lower(trimspace(method))
        ]
      })
    }
  }
}
