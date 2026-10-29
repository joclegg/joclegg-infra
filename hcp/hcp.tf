# HCP Terraform manages itself: the organisation and puzzles-hcp, the workspace
# that holds this state. Both were made by hand once and imported. Destroying
# either would delete the state mid-run, so prevent_destroy stays on.
# The workspaces for the other folders are created here too, as they're added.

import {
  to = tfe_organization.joclegg
  id = "joclegg"
}

resource "tfe_organization" "joclegg" {
  name  = "joclegg"
  email = "jo_clegg@hotmail.com"

  lifecycle {
    prevent_destroy = true
  }
}

import {
  to = tfe_workspace.hcp
  id = "joclegg/puzzles-hcp"
}

resource "tfe_workspace" "hcp" {
  name         = "puzzles-hcp"
  organization = tfe_organization.joclegg.name
  description  = "HCP Terraform itself, from hcp/ in joclegg/puzzles-infra."

  # Runs come from GitHub Actions, not from HCP watching the repository.
  file_triggers_enabled = false
  queue_all_runs        = false

  lifecycle {
    prevent_destroy = true
  }
}

import {
  to = tfe_workspace_settings.hcp
  id = "joclegg/puzzles-hcp"
}

# Local execution: HCP only stores state; plans and applies run in GitHub Actions.
resource "tfe_workspace_settings" "hcp" {
  workspace_id   = tfe_workspace.hcp.id
  execution_mode = "local"
}

# One workspace per folder. Local execution, like puzzles-hcp.
locals {
  workspaces = {
    github = "GitHub repositories and their settings, from github/ in joclegg/puzzles-infra."
  }
}

resource "tfe_workspace" "folder" {
  for_each = local.workspaces

  name         = "puzzles-${each.key}"
  organization = tfe_organization.joclegg.name
  description  = each.value

  file_triggers_enabled = false
  queue_all_runs        = false

  lifecycle {
    prevent_destroy = true
  }
}

# puzzles-github was created by an early `terraform init` in github/, so it's
# imported rather than created.
import {
  to = tfe_workspace.folder["github"]
  id = "joclegg/puzzles-github"
}

import {
  to = tfe_workspace_settings.folder["github"]
  id = "joclegg/puzzles-github"
}

resource "tfe_workspace_settings" "folder" {
  for_each = local.workspaces

  workspace_id   = tfe_workspace.folder[each.key].id
  execution_mode = "local"
}
