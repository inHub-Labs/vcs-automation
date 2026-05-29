# VCS Automation (GitHub Organization Management)

This repository manages GitHub Organization governance with Terraform:
- repositories;
- repository-level branch strategy and rulesets;
- repository access through teams;
- teams and team memberships;
- organization members;
- organization role assignments through teams.

YAML is used only for repository definitions (`repositories.yaml`).

## What Is Active Now

Enabled in root `main.tf`:
- `module.repositories`
- `module.members`
- `module.teams`
- `module.org_roles`

Currently commented out (not applied):
- `module.org_settings`
- `module.organization_rulesets`

## Quick Workflow

1. Create a branch from `main`.
2. Update one or more input files:
- `repositories.yaml`
- `teams.auto.tfvars`
- `organization_members.auto.tfvars`
- `role_assignments.auto.tfvars`
- `organization_settings.auto.tfvars` (future use, module is disabled now)
3. Open a PR to `main`.
4. Wait for successful `fmt/init/validate/plan` in PR checks.
5. After merge to `main`, workflow runs `terraform apply`.

## Full Configuration Reference

### 1) `repositories.yaml`

Supported formats:
- top-level list of repositories;
- object with `repositories` key.

Minimal valid repository object:

```yaml
- name: sample-repo
  description: Sample description
  topics: [service]
  owners: [Samvel27]
```

Fields:
- `name` (`string`, required, non-empty)
- `description` (`string`, required, non-empty)
- `topics` (`list(string)`, required, at least one value)
- `owners` (`list(string)`, required, at least one value)
- `branch_strategy` (`github_flow|simplified_gitflow|gitflow`, optional, default: `null`)
- `visibility` (`public|private|internal`, optional, default: `private`)
- `strategy_configurable` (`object`, optional, default: `{}`)
- `team_access` (`list(object)`, optional)
- `ignore_team_access` (`list(object)`, optional, default: `[]`)

Normalization and defaults:
- `branch_strategy` is normalized to lower case with `-` and spaces converted to `_`.
- `visibility` defaults to `private` when omitted or empty.
- `topics` are trimmed and normalized to lower case.
- `terraform-managed` topic is always auto-added.
- if `team_access` is omitted, no team grants are created from this field.
- if `team_access: []` is explicitly set, no team grants are created from this field.
- `user_access` is no longer supported; repository access must be granted through `team_access` only.

`team_access[]`:
- `team_slug` (`string`, required)
- `permission` (`pull|triage|push|maintain|admin`, default: `admin`)
- duplicate `team_slug` is not allowed per repository.

`ignore_team_access[]`:
- `team_slug` (`string`, required)
- duplicate `team_slug` is not allowed.

### Branch Strategy Presets

`github_flow`:
- protected branches: `main`
- allowed branch names: `main`, `feature/*`
- default merge methods for `main`: `["squash"]`

`simplified_gitflow`:
- creates `develop` branch
- protected branches: `main`, `develop`
- allowed branch names: `main`, `develop`, `feature/*`, `hot-fix/*`
- default merge methods:
  - `main`: `["squash"]`
  - `develop`: `["merge", "squash"]`

`gitflow`:
- creates `develop` branch
- protected branches: `main`, `develop`, `release/*`
- allowed branch names: `main`, `develop`, `feature/*`, `release/*`, `hot-fix/*`
- default merge methods:
  - `main`: `["merge", "squash"]`
  - `develop`: `["merge", "squash"]`
  - `release/*`: `["merge"]`

Baseline protection behavior:
- PR required before merge;
- force push blocked;
- delete restricted for `main`;
- required approvals:
  - `gitflow.main` = `2`
  - all other protected branches = `1`;
- stale approvals dismissed;
- review conversation resolution required;
- required status checks are enabled only when non-empty checks are provided for a branch.

### `strategy_configurable` (allowed overrides)

```yaml
strategy_configurable:
  required_approvals:
    main: 2
  status_checks:
    main: [ci/build, ci/test]
  require_linear_history:
    main: true
  require_code_owner_review:
    main: true
  require_approval_of_most_recent_push:
    main: true
  allowed_merge_methods:
    main: [squash, rebase]
```

Rules:
- `required_approvals`: `0..10`
- `allowed_merge_methods`: only `merge|squash|rebase`, list must be non-empty
- keys in `strategy_configurable` must match protected branches of the selected strategy:
  - `github_flow`: `main`
  - `simplified_gitflow`: `main`, `develop`
  - `gitflow`: `main`, `develop`, `release/*`
- invalid keys cause Terraform precondition error.

If `branch_strategy` is omitted or `null`:
- no strategy branches are created;
- no repository branch rulesets are created;
- default branch stays at `repository_init_branch` (`main` by default).

### 2) `teams.auto.tfvars`

```hcl
teams = [
  {
    name        = "platform-team"
    description = "Platform engineering"
    privacy     = "closed"
    members = [
      {
        username = "gnersisyann"
        role     = "member"
      }
    ]
  }
]
```

Fields:
- `name` (`string`, required, slug format: `^[a-z0-9-]+$`)
- `description` (`string`, optional, default: `""`)
- `privacy` (`closed|secret`, optional, default: `closed`)
- `members` (`list(object)`, optional, default: `[]`)

`members[]`:
- `username` (`string`, required)
- `role` (`member|maintainer`, optional, default: `member`)

Resources used:
- `github_team`
- `github_team_membership`

### 3) `organization_members.auto.tfvars`

```hcl
organization_members = [
  {
    username = "some-user"
    role     = "member"
  }
]
```

Fields:
- `username` (`string`, required, non-empty)
- `role` (`member|admin`, optional, default: `member`)

Resource used: `github_membership`.

### 4) `role_assignments.auto.tfvars`

```hcl
role_assignment = {
  pull      = ["platform-team"]
  cicdadmin = ["devops-team"]
}
```

Supported aliases:
- `pull`
- `push`
- `triage`
- `maintain`
- `admin`
- `cicdadmin`
- `securitymanager`
- `appmanager`

Alias mapping:
- `pull -> all_repo_read`
- `push -> all_repo_write`
- `triage -> all_repo_triage`
- `maintain -> all_repo_maintain`
- `admin -> all_repo_admin`
- `cicdadmin -> ci_cd_admin`
- `securitymanager -> security_manager`
- `appmanager -> app_manager`

Behavior:
- module queries available org roles via `data.github_organization_roles`;
- unknown requested role key causes Terraform precondition error;
- assignments are created via `github_organization_role_team`;
- direct user role assignments are not supported by the input model.

### 5) `organization_settings.auto.tfvars` (module currently disabled)

File exists, but `module.org_settings` is commented in root.

Example:

```hcl
organization_settings = {
  billing_email                   = "finance@example.com"
  default_repository_permission   = "read"
  members_can_create_repositories = false
}
```

When module is enabled, supported fields are:
- `billing_email`
- `has_organization_projects`
- `has_repository_projects`
- `default_repository_permission`
- `members_can_create_repositories`
- `members_can_create_public_repositories`
- `members_can_create_private_repositories`
- `members_can_create_internal_repositories`
- `members_can_create_pages`
- `members_can_create_public_pages`
- `members_can_create_private_pages`
- `members_can_fork_private_repositories`
- `web_commit_signoff_required`
- `advanced_security_enabled_for_new_repositories`
- `dependabot_alerts_enabled_for_new_repositories`
- `dependabot_security_updates_enabled_for_new_repositories`
- `dependency_graph_enabled_for_new_repositories`
- `secret_scanning_enabled_for_new_repositories`
- `secret_scanning_push_protection_enabled_for_new_repositories`

## Examples (Collapsible)

<details>
<summary>Example: minimal repository without branch strategy</summary>

```yaml
- name: service-no-strategy
  description: Repository without strategy rulesets
  topics: [service]
  owners: [Samvel27]
  visibility: private
```

Effect:
- repository is created;
- `README.md` and `CODEOWNERS` are created;
- no team grants are created because `team_access` is omitted;
- strategy branches/rulesets are not created.

</details>

<details>
<summary>Example: github_flow with custom required checks</summary>

```yaml
- name: service-github-flow
  description: GitHub flow with checks
  topics: [service, api]
  owners: [Samvel27, gnersisyann]
  branch_strategy: github_flow
  visibility: private
  strategy_configurable:
    status_checks:
      main: [ci/build, ci/test]
    require_code_owner_review:
      main: true
```

</details>

<details>
<summary>Example: simplified_gitflow</summary>

```yaml
- name: service-simplified-gitflow
  description: Simplified gitflow repository
  topics: [service]
  owners: [Samvel27]
  branch_strategy: simplified_gitflow
  team_access:
    - team_slug: platform-team
      permission: maintain
```

</details>

<details>
<summary>Example: gitflow with release/* overrides</summary>

```yaml
- name: service-gitflow
  description: Full gitflow profile
  topics: [service]
  owners: [Samvel27]
  branch_strategy: gitflow
  strategy_configurable:
    required_approvals:
      main: 2
      develop: 1
      release/*: 1
    allowed_merge_methods:
      main: [merge, squash]
      develop: [merge, squash]
      release/*: [merge]
```

</details>

<details>
<summary>Example: repository with no team_access</summary>

```yaml
- name: service-no-team-access
  description: Repo with no direct access grants
  topics: [service]
  owners: [Samvel27]
  visibility: private
  team_access: []
```

</details>

<details>
<summary>Example: ignore_team_access (keep specific team unmanaged)</summary>

```yaml
- name: service-ignore-team
  description: Keep external team assignment unmanaged
  topics: [service]
  owners: [Samvel27]
  branch_strategy: github_flow
  team_access:
    - team_slug: platform-team
      permission: admin
  ignore_team_access:
    - team_slug: legacy-team
```

</details>

<details>
<summary>Example: teams.auto.tfvars</summary>

```hcl
teams = [
  {
    name        = "platform-team"
    description = "Platform team"
    privacy     = "closed"
    members = [
      { username = "Samvel27", role = "maintainer" },
      { username = "gnersisyann", role = "member" }
    ]
  }
]
```

</details>

<details>
<summary>Example: organization_members.auto.tfvars</summary>

```hcl
organization_members = [
  { username = "Samvel27", role = "member" },
  { username = "gnersisyann", role = "admin" }
]
```

</details>

<details>
<summary>Example: role_assignments.auto.tfvars (full)</summary>

```hcl
role_assignment = {
  pull            = ["platform-team"]
  push            = ["release-team"]
  triage          = ["support-team"]
  maintain        = ["maintainers-team"]
  admin           = ["org-admin-team"]
  cicdadmin       = ["devops-team"]
  securitymanager = ["security-team"]
  appmanager      = ["github-apps-team"]
}
```

</details>

<details>
<summary>Example: organization_settings.auto.tfvars (future use)</summary>

```hcl
organization_settings = {
  billing_email                                                = "finance@example.com"
  default_repository_permission                                = "read"
  members_can_create_repositories                              = false
  members_can_fork_private_repositories                        = false
  advanced_security_enabled_for_new_repositories               = true
  dependabot_alerts_enabled_for_new_repositories               = true
  dependabot_security_updates_enabled_for_new_repositories     = true
  dependency_graph_enabled_for_new_repositories                = true
  secret_scanning_enabled_for_new_repositories                 = true
  secret_scanning_push_protection_enabled_for_new_repositories = true
}
```

</details>

## Auto-Generated in Each Managed Repository

- `README.md` bootstrap file with link to `vcs-automation`
- `CODEOWNERS` generated from `owners` (`@username` format)
- default branch behavior:
  - without strategy: `repository_init_branch` (`main`)
  - with strategy: `main` and `develop` when strategy requires it

## Important Edge Cases

- `team_access.team_slug` and `team_access.permission` are normalized to lower case.
- empty `team_slug`/`username` values are filtered during normalization; validations also exist.
- if `strategy_configurable` contains unsupported branch keys for selected strategy, `terraform plan` fails with precondition error.
- root variables for advanced repository toggles (`has_wiki`, merge settings, etc.) are currently not passed from root module call, so repository module defaults are used.

## Architecture

- [`locals.tf`](./locals.tf): input loading and normalization.
- [`main.tf`](./main.tf): module orchestration.
- [`modules/repository`](./modules/repository): repositories, branches, rulesets, collaborators, bootstrap files.
- [`modules/organization/team`](./modules/organization/team): teams and memberships.
- [`modules/organization/membership`](./modules/organization/membership): org memberships.
- [`modules/organization/org_roles`](./modules/organization/org_roles): organization role assignments.
- [`modules/organization/org_settings`](./modules/organization/org_settings): org settings (implemented, disabled in root).
- [`modules/organization/rulesets`](./modules/organization/rulesets): org-wide rulesets (implemented, disabled in root).

## CI/CD

- [`terraform-pr-validation.yml`](./.github/workflows/terraform-pr-validation.yml):
  - `terraform fmt -check`
  - `terraform init`
  - `terraform validate`
  - `terraform plan`
  - PR comment with results
- [`terraform.yml`](./.github/workflows/terraform.yml):
  - `terraform init/validate/plan`
  - `terraform apply` on `main`
- [`linter.yml`](./.github/workflows/linter.yml):
  - Super-Linter run
  - PR comment with result
