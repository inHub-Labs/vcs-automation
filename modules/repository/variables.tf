variable "name" {
  type = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "Repository name must not be empty."
  }
}

variable "description" {
  type = string

  validation {
    condition     = length(trimspace(var.description)) > 0
    error_message = "Repository description must not be empty."
  }
}

variable "topics" {
  type = list(string)

  validation {
    condition     = length(var.topics) > 0
    error_message = "Repository must have at least one topic."
  }

  validation {
    condition     = alltrue([for topic in var.topics : length(trimspace(topic)) > 0])
    error_message = "Repository topics must not contain empty values."
  }
}

variable "owners" {
  type = list(string)

  validation {
    condition     = length(var.owners) > 0
    error_message = "Repository must define at least one owner."
  }

  validation {
    condition     = alltrue([for owner in var.owners : length(trimspace(owner)) > 0])
    error_message = "Repository owners must not contain empty values."
  }
}

variable "repository_init_branch" {
  type    = string
  default = "main"

  validation {
    condition     = length(trimspace(var.repository_init_branch)) > 0
    error_message = "Repository init branch name must not be empty."
  }
}

variable "branch_strategy" {
  type    = string
  default = null

  validation {
    condition = var.branch_strategy == null || contains([
      "github_flow",
      "simplified_gitflow",
      "gitflow"
    ], lower(trimspace(var.branch_strategy)))
    error_message = "branch_strategy must be null or one of: github_flow, simplified_gitflow, gitflow."
  }
}

variable "strategy_configurable" {
  description = "Allowed branch-strategy overrides (strictness only, not branch topology)."
  type = object({
    required_approvals                   = optional(map(number), {})
    status_checks                        = optional(map(list(string)), {})
    require_linear_history               = optional(map(bool), {})
    require_code_owner_review            = optional(map(bool), {})
    require_approval_of_most_recent_push = optional(map(bool), {})
    allowed_merge_methods                = optional(map(list(string)), {})
  })
  default = {}

  validation {
    condition = alltrue([
      for branch_name, approvals in var.strategy_configurable.required_approvals :
      approvals >= 0 && approvals <= 10
    ])
    error_message = "strategy_configurable.required_approvals values must be between 0 and 10."
  }

  validation {
    condition = alltrue(flatten([
      for branch_name, checks in var.strategy_configurable.status_checks :
      [for check_name in checks : length(trimspace(check_name)) > 0]
    ]))
    error_message = "strategy_configurable.status_checks values must not contain empty check names."
  }

  validation {
    condition = alltrue(flatten([
      for branch_name, methods in var.strategy_configurable.allowed_merge_methods :
      [for method in methods : contains(["merge", "squash", "rebase"], lower(trimspace(method)))]
    ]))
    error_message = "strategy_configurable.allowed_merge_methods supports only: merge, squash, rebase."
  }

  validation {
    condition = alltrue([
      for branch_name, methods in var.strategy_configurable.allowed_merge_methods :
      length(methods) > 0
    ])
    error_message = "strategy_configurable.allowed_merge_methods values must have at least one merge method per branch."
  }
}

variable "visibility" {
  type    = string
  default = "private"

  validation {
    condition     = contains(["public", "private", "internal"], var.visibility)
    error_message = "Visibility must be one of: public, private, internal."
  }
}

variable "team_access" {
  description = "Repository access for teams."
  type = list(object({
    team_slug  = string
    permission = optional(string, "admin")
  }))
  default = []

  validation {
    condition = alltrue([
      for assignment in var.team_access :
      length(trimspace(assignment.team_slug)) > 0
    ])
    error_message = "team_access.team_slug must not be empty."
  }

  validation {
    condition = alltrue([
      for assignment in var.team_access :
      contains(["pull", "triage", "push", "maintain", "admin"], lower(trimspace(try(assignment.permission, "admin"))))
    ])
    error_message = "team_access.permission must be one of: pull, triage, push, maintain, admin."
  }

  validation {
    condition = length(distinct([
      for assignment in var.team_access :
      lower(trimspace(assignment.team_slug))
    ])) == length(var.team_access)
    error_message = "team_access must not contain duplicate team_slug values for a single repository."
  }
}

variable "ignore_team_access" {
  description = "Teams to ignore while reconciling repository collaborators."
  type = list(object({
    team_slug = string
  }))
  default = []

  validation {
    condition = alltrue([
      for assignment in var.ignore_team_access :
      length(trimspace(assignment.team_slug)) > 0
    ])
    error_message = "ignore_team_access.team_slug must not be empty."
  }

  validation {
    condition = length(distinct([
      for assignment in var.ignore_team_access :
      lower(trimspace(assignment.team_slug))
    ])) == length(var.ignore_team_access)
    error_message = "ignore_team_access must not contain duplicate team_slug values for a single repository."
  }
}

variable "has_issues" {
  type    = bool
  default = true
}

variable "has_discussions" {
  type    = bool
  default = false
}

variable "has_projects" {
  type    = bool
  default = true
}

variable "has_wiki" {
  type    = bool
  default = true
}

variable "allow_merge_commit" {
  type    = bool
  default = true
}

variable "allow_squash_merge" {
  type    = bool
  default = true
}

variable "allow_rebase_merge" {
  type    = bool
  default = true
}

variable "allow_auto_merge" {
  type    = bool
  default = false
}

variable "allow_forking" {
  type    = bool
  default = null
}

variable "squash_merge_commit_title" {
  type    = string
  default = null

  validation {
    condition = var.squash_merge_commit_title == null || contains([
      "PR_TITLE",
      "COMMIT_OR_PR_TITLE"
    ], var.squash_merge_commit_title)
    error_message = "squash_merge_commit_title must be one of: PR_TITLE, COMMIT_OR_PR_TITLE."
  }

  validation {
    condition     = var.squash_merge_commit_title == null || var.allow_squash_merge
    error_message = "squash_merge_commit_title can be set only when allow_squash_merge is true."
  }
}

variable "squash_merge_commit_message" {
  type    = string
  default = null

  validation {
    condition = var.squash_merge_commit_message == null || contains([
      "PR_BODY",
      "COMMIT_MESSAGES",
      "BLANK"
    ], var.squash_merge_commit_message)
    error_message = "squash_merge_commit_message must be one of: PR_BODY, COMMIT_MESSAGES, BLANK."
  }

  validation {
    condition     = var.squash_merge_commit_message == null || var.allow_squash_merge
    error_message = "squash_merge_commit_message can be set only when allow_squash_merge is true."
  }
}

variable "merge_commit_title" {
  type    = string
  default = null

  validation {
    condition = var.merge_commit_title == null || contains([
      "PR_TITLE",
      "MERGE_MESSAGE"
    ], var.merge_commit_title)
    error_message = "merge_commit_title must be one of: PR_TITLE, MERGE_MESSAGE."
  }

  validation {
    condition     = var.merge_commit_title == null || var.allow_merge_commit
    error_message = "merge_commit_title can be set only when allow_merge_commit is true."
  }
}

variable "merge_commit_message" {
  type    = string
  default = null

  validation {
    condition = var.merge_commit_message == null || contains([
      "PR_BODY",
      "PR_TITLE",
      "BLANK"
    ], var.merge_commit_message)
    error_message = "merge_commit_message must be one of: PR_BODY, PR_TITLE, BLANK."
  }

  validation {
    condition     = var.merge_commit_message == null || var.allow_merge_commit
    error_message = "merge_commit_message can be set only when allow_merge_commit is true."
  }
}

variable "delete_branch_on_merge" {
  type    = bool
  default = false
}

variable "web_commit_signoff_required" {
  type    = bool
  default = false
}

variable "archived" {
  type    = bool
  default = false
}

variable "archive_on_destroy" {
  type    = bool
  default = false
}

variable "vulnerability_alerts" {
  type    = bool
  default = null
}

variable "allow_update_branch" {
  type    = bool
  default = false
}

