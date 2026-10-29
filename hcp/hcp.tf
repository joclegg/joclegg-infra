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
