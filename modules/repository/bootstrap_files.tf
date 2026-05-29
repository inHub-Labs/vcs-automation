resource "github_repository_file" "codeowners" {
  repository          = github_repository.this.name
  file                = "CODEOWNERS"
  branch              = local.default_branch
  overwrite_on_create = true

  content = format("* %s", join(" ", [
    for owner in var.owners :
    "@${trimprefix(trimspace(owner), "@")}"
  ]))

  depends_on = [github_branch_default.this]
}

resource "github_repository_file" "readme" {
  repository          = github_repository.this.name
  file                = "README.md"
  branch              = local.default_branch
  overwrite_on_create = true

  content = <<-EOT
  # ${var.name}

  ${var.description}

  This repository is managed by [vcs-automation](${github_repository.this.homepage_url}).
  Infrastructure and repository governance changes should be requested there.
  EOT

  lifecycle {
    ignore_changes = [content]
  }

  depends_on = [github_branch_default.this]
}
