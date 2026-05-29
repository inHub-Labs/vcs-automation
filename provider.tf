terraform {
  required_version = ">= 1.14.0"

  backend "s3" {
    bucket       = "gnersisyan-tf-state"
    key          = "vcs-automation/terraform.tfstate"
    region       = "eu-north-1"
    use_lockfile = true
  }

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.11.0"
    }
  }
}

provider "github" {
  owner = var.github_organization

  app_auth {}
}
