# HCP Terraform manages itself: the organisation and joclegg-hcp, the workspace
# that holds this state. Both were made by hand once and imported. Destroying
# either would delete the state mid-run, so prevent_destroy stays on.
# The workspaces for the other folders are created here too, as they're added.

resource "tfe_organization" "joclegg" {
  name  = "joclegg"
  email = "jo_clegg@hotmail.com"

  lifecycle {
    prevent_destroy = true
  }
}

resource "tfe_workspace" "hcp" {
  name         = "joclegg-hcp"
  organization = tfe_organization.joclegg.name
  description  = "HCP Terraform itself, from hcp/ in joclegg/joclegg-infra."

  # Runs come from GitHub Actions, not from HCP watching the repository.
  file_triggers_enabled = false
  queue_all_runs        = false

  lifecycle {
    prevent_destroy = true
  }
}

# Local execution: HCP only stores state; plans and applies run in GitHub Actions.
resource "tfe_workspace_settings" "hcp" {
  workspace_id   = tfe_workspace.hcp.id
  execution_mode = "local"
}

# One workspace per folder. Local execution, like joclegg-hcp.
locals {
  workspaces = {
    github   = "Every repository on the joclegg GitHub account, from github/ in joclegg/joclegg-infra."
    supabase = "The Puzzles Supabase project and its auth settings, from supabase/ in joclegg/joclegg-infra."
  }
}

resource "tfe_workspace" "folder" {
  for_each = local.workspaces

  name         = "joclegg-${each.key}"
  organization = tfe_organization.joclegg.name
  description  = each.value

  file_triggers_enabled = false
  queue_all_runs        = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "tfe_workspace_settings" "folder" {
  for_each = local.workspaces

  workspace_id   = tfe_workspace.folder[each.key].id
  execution_mode = "local"
}
