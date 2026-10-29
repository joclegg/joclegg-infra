# HCP Terraform manages itself: the organisation and the workspace that holds
# this state. Both were made by hand once and imported. Destroying either would
# delete the state mid-run, so prevent_destroy stays on.

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
  to = tfe_workspace.puzzles
  id = "joclegg/puzzles"
}

resource "tfe_workspace" "puzzles" {
  name         = "puzzles"
  organization = tfe_organization.joclegg.name
  description  = "Infrastructure for the Puzzles apps, from joclegg/puzzles-infra."

  # Runs come from GitHub Actions, not from HCP watching the repository.
  file_triggers_enabled = false
  queue_all_runs        = false

  lifecycle {
    prevent_destroy = true
  }
}

import {
  to = tfe_workspace_settings.puzzles
  id = "joclegg/puzzles"
}

# Local execution: HCP only stores state; plans and applies run in GitHub Actions.
resource "tfe_workspace_settings" "puzzles" {
  workspace_id   = tfe_workspace.puzzles.id
  execution_mode = "local"
}
