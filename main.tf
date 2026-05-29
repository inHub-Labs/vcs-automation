module "repositories" {
  source   = "./modules/repository"
  for_each = local.repositories

  name                  = each.value.name
  description           = each.value.description
  topics                = each.value.topics
  owners                = each.value.owners
  branch_strategy       = each.value.branch_strategy
  strategy_configurable = each.value.strategy_configurable
  visibility            = each.value.visibility
  team_access           = each.value.team_access
  ignore_team_access    = each.value.ignore_team_access

  depends_on = [module.teams]
}

module "members" {
  source   = "./modules/organization/membership"
  for_each = local.members

  username = each.value.username
  role     = each.value.role
}

module "teams" {
  source   = "./modules/organization/team"
  for_each = local.teams

  name        = each.value.name
  description = each.value.description
  privacy     = each.value.privacy
  members     = each.value.members

  depends_on = [module.members]
}

# module "org_settings" {
#   source = "./modules/organization/org_settings"

#   billing_email                           = local.org_settings.billing_email

#   has_organization_projects               = try(local.org_settings.has_organization_projects, null)
#   has_repository_projects                 = try(local.org_settings.has_repository_projects, null)
#   default_repository_permission           = try(local.org_settings.default_repository_permission, "read")

#   members_can_create_repositories         = try(local.org_settings.members_can_create_repositories, null)
#   members_can_create_public_repositories  = try(local.org_settings.members_can_create_public_repositories, null)
#   members_can_create_private_repositories = try(local.org_settings.members_can_create_private_repositories, null)
#   members_can_create_internal_repositories = try(local.org_settings.members_can_create_internal_repositories, null)
#   members_can_create_pages                = try(local.org_settings.members_can_create_pages, null)
#   members_can_create_public_pages         = try(local.org_settings.members_can_create_public_pages, null)
#   members_can_create_private_pages        = try(local.org_settings.members_can_create_private_pages, null)
#   members_can_fork_private_repositories   = try(local.org_settings.members_can_fork_private_repositories, null)

#   web_commit_signoff_required             = try(local.org_settings.web_commit_signoff_required, null)
#   advanced_security_enabled_for_new_repositories = try(local.org_settings.advanced_security_enabled_for_new_repositories, null)
#   dependabot_alerts_enabled_for_new_repositories = try(local.org_settings.dependabot_alerts_enabled_for_new_repositories, null)
#   dependabot_security_updates_enabled_for_new_repositories = try(local.org_settings.dependabot_security_updates_enabled_for_new_repositories, null)
#   dependency_graph_enabled_for_new_repositories = try(local.org_settings.dependency_graph_enabled_for_new_repositories, null)
#   secret_scanning_enabled_for_new_repositories = try(local.org_settings.secret_scanning_enabled_for_new_repositories, true)
#   secret_scanning_push_protection_enabled_for_new_repositories = try(local.org_settings.secret_scanning_push_protection_enabled_for_new_repositories, true)
# }

# module "org_roles" {
#   source = "./modules/organization/org_roles"
#
#   team_assignments = local.org_role_team_assignments
#
#   depends_on = [module.members, module.teams]
# }

# module "organization_rulesets" {
#   source = "./modules/organization/rulesets"
# }
