# Actions variables for the other repositories: values other roots output that
# aren't secret, so a workflow log can show them.

data "tfe_outputs" "google" {
  workspace = "joclegg-google"
}

locals {
  actions_variables = {
    "puzzles-android" = {
      # The release workflow signs in to Google Play with these through
      # Workload Identity Federation, so it needs no key.
      PLAY_WORKLOAD_IDENTITY_PROVIDER = data.tfe_outputs.google.nonsensitive_values.workload_identity_provider
      PLAY_SERVICE_ACCOUNT            = data.tfe_outputs.google.nonsensitive_values.play_publisher_email
    }
    "puzzles-ios" = {
      # Only the key itself is secret. Apple made the key by hand in App Store
      # Connect, so these come from there, not from another root.
      APP_STORE_CONNECT_KEY_ID    = "ABTC5P8RWX"
      APP_STORE_CONNECT_ISSUER_ID = "546b32cf-1a68-48f3-9223-570e2fe1fb93"
      APPLE_TEAM_ID               = "6TATRT9BZQ"
    }
  }

  actions_variable_list = merge([
    for repo, variables in local.actions_variables : {
      for name, value in variables : "${repo}/${name}" => { repo = repo, name = name, value = value }
    }
  ]...)
}

resource "github_actions_variable" "this" {
  for_each = local.actions_variable_list

  repository    = module.repository[each.value.repo].name
  variable_name = each.value.name
  value         = each.value.value
}
