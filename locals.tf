locals {
  organization_role_catalog = {
    pull            = "all_repo_read"
    push            = "all_repo_write"
    triage          = "all_repo_triage"
    maintain        = "all_repo_maintain"
    admin           = "all_repo_admin"
    cicdadmin       = "ci_cd_admin"
    securitymanager = "security_manager"
    appmanager      = "app_manager"
  }

  repository_config_file = "repositories.yaml"
  repository_config_raw  = try(yamldecode(file("${path.module}/${local.repository_config_file}")), [])

  repository_configs = try(
    tolist(local.repository_config_raw.repositories),
    tolist(local.repository_config_raw),
    []
  )

  repositories = {
    for repo in local.repository_configs : repo.name => merge(repo, {
      branch_strategy       = length(trimspace(try(repo.branch_strategy, ""))) > 0 ? lower(replace(replace(trimspace(try(repo.branch_strategy, "")), "-", "_"), " ", "_")) : null
      visibility            = try(length(trimspace(repo.visibility)) > 0 ? lower(trimspace(repo.visibility)) : "private", "private")
      strategy_configurable = try(repo.strategy_configurable, {})
      team_access = can(repo.team_access) ? [
        for access in try(repo.team_access, []) : {
          team_slug  = lower(trimspace(access.team_slug))
          permission = lower(trimspace(try(access.permission, "admin")))
        }
        if length(trimspace(try(access.team_slug, ""))) > 0
      ] : []
      ignore_team_access = [
        for access in try(repo.ignore_team_access, []) : {
          team_slug = lower(trimspace(access.team_slug))
        }
        if length(trimspace(try(access.team_slug, ""))) > 0
      ]

      topics = distinct(concat(
        [
          for topic in try(repo.topics, []) :
          lower(trimspace(topic))
          if length(trimspace(topic)) > 0
        ],
        ["terraform-managed"]
      ))
    })
  }

  team_defaults = {
    description = ""
    privacy     = "closed"
    members     = []
  }

  normalized_teams = [
    for team in var.teams : merge(local.team_defaults, team, {
      slug = lower(trimspace(team.name))
      members = [
        for member in try(team.members, []) : {
          username = trimspace(member.username)
          role     = lower(trimspace(try(member.role, "member")))
        }
        if length(trimspace(try(member.username, ""))) > 0
      ]
    })
  ]
  teams = { for team in local.normalized_teams : team.name => team }

  members = {
    for m in var.organization_members : trimspace(m.username) => merge({
      role = "member"
      }, m, {
      username = trimspace(m.username)
      role     = lower(trimspace(try(m.role, "member")))
    })
  }

  role_assignments_by_alias = {
    for role_alias, teams in var.role_assignment :
    lower(trimspace(role_alias)) => try(tolist(teams), [])
    if length(trimspace(role_alias)) > 0
  }

  org_role_team_pairs = flatten([
    for role_alias, teams in local.role_assignments_by_alias : [
      for team_slug in try(tolist(teams), []) : {
        role_key  = lower(local.organization_role_catalog[role_alias])
        role_name = local.organization_role_catalog[role_alias]
        team_slug = trimspace(team_slug)
      }
      if length(trimspace(team_slug)) > 0
    ]
  ])

  org_role_team_assignments = {
    for assignment in local.org_role_team_pairs :
    "${assignment.role_key}::${lower(assignment.team_slug)}" => assignment
  }

  # org_settings = {
  #   for key, value in var.organization_settings :
  #   key => value
  #   if value != null
  # }
}
