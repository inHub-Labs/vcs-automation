locals {
  allowed_ref_patterns = [
    "refs/heads/main",
    "refs/heads/develop",
    "refs/heads/feature/*",
    "refs/heads/hot-fix/*",
    "refs/heads/release/*"
  ]
}

resource "github_organization_ruleset" "main_branch_force_push_guard" {
  name        = "protect-main-from-force-push"
  target      = "branch"
  enforcement = "disabled"

  conditions {
    repository_name {
      include = ["~ALL"]
      exclude = []
    }

    ref_name {
      include = ["refs/heads/main"]
      exclude = []
    }
  }

  rules {
    non_fast_forward = true
  }
}

resource "github_organization_ruleset" "branch_name_allowlist" {
  name        = "branch-name-allowlist"
  target      = "branch"
  enforcement = "active"

  conditions {
    repository_name {
      include = ["~ALL"]
      exclude = []
    }

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
