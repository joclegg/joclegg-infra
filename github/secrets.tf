# Actions secrets for the other repositories. Each value is stored once, as a
# joclegg-infra secret of the same name, and the workflow passes it in as
# TF_VAR_<name>. Values end up in this workspace's state.

variable "SUPABASE_ACCESS_TOKEN" {
  description = "Lets puzzles-backend push migrations to the Supabase project."
  type        = string
  sensitive   = true
}

variable "PUZZLES_KEYSTORE_BASE64" {
  description = "The Android release keystore, base64-encoded."
  type        = string
  sensitive   = true
}

variable "PUZZLES_KEYSTORE_PASSWORD" {
  type      = string
  sensitive = true
}

variable "PUZZLES_KEY_ALIAS" {
  type      = string
  sensitive = true
}

variable "PUZZLES_KEY_PASSWORD" {
  type      = string
  sensitive = true
}

locals {
  # joclegg-infra reads its own copies, so it isn't listed.
  actions_secrets = {
    "puzzles-android" = {
      PUZZLES_KEYSTORE_BASE64   = var.PUZZLES_KEYSTORE_BASE64
      PUZZLES_KEYSTORE_PASSWORD = var.PUZZLES_KEYSTORE_PASSWORD
      PUZZLES_KEY_ALIAS         = var.PUZZLES_KEY_ALIAS
      PUZZLES_KEY_PASSWORD      = var.PUZZLES_KEY_PASSWORD
    }
    "puzzles-backend" = {
      SUPABASE_ACCESS_TOKEN = var.SUPABASE_ACCESS_TOKEN
    }
  }

  # Keys aren't secret, only values, so for_each can use them.
  actions_secret_list = merge([
    for repo, secrets in local.actions_secrets : {
      for name in nonsensitive(keys(secrets)) : "${repo}/${name}" => { repo = repo, name = name }
    }
  ]...)
}

resource "github_actions_secret" "this" {
  for_each = local.actions_secret_list

  repository      = module.repository[each.value.repo].name
  secret_name     = each.value.name
  plaintext_value = local.actions_secrets[each.value.repo][each.value.name]
}
