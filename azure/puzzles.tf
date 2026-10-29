# The Puzzles app registration, for "Sign in with Microsoft" through Supabase.
# supabase/ reads its client ID and secret from this workspace's outputs.

data "azuread_client_config" "current" {}

data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "msgraph" {
  client_id = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"]
}

resource "azuread_application" "puzzles" {
  display_name = "Puzzles"

  # Owned by joclegg-infra-github, the identity Terraform signs in as: its
  # Application.ReadWrite.OwnedBy permission only reaches apps it owns.
  owners = [data.azuread_client_config.current.object_id]

  # Personal accounts (Outlook, Hotmail, Xbox) and any work or school account.
  sign_in_audience = "AzureADandPersonalMicrosoftAccount"

  # Personal accounts need v2 access tokens.
  api {
    requested_access_token_version = 2
  }

  web {
    redirect_uris = ["https://nrlmaucpuesfmvqhtupe.supabase.co/auth/v1/callback"]
  }

  # Supabase needs the email in the ID token. xms_edov says whether the
  # email's domain is verified by the account's organisation.
  optional_claims {
    id_token {
      name = "email"
    }
    id_token {
      name = "xms_edov"
    }
  }

  # Sign-in only: openid, email and profile, which need no admin consent.
  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"]

    dynamic "resource_access" {
      for_each = ["openid", "email", "profile"]

      content {
        id   = data.azuread_service_principal.msgraph.oauth2_permission_scope_ids[resource_access.value]
        type = "Scope"
      }
    }
  }
}

# The client secret is replaced every 6 months. Each apply after that makes a
# new one, and supabase/ picks it up on its next run.
resource "time_rotating" "puzzles_secret" {
  rotation_days = 180
}

resource "azuread_application_password" "puzzles" {
  application_id = azuread_application.puzzles.id
  display_name   = "Supabase"

  rotate_when_changed = {
    rotation = time_rotating.puzzles_secret.id
  }
}

output "puzzles_client_id" {
  value = azuread_application.puzzles.client_id
}

output "puzzles_client_secret" {
  value     = azuread_application_password.puzzles.value
  sensitive = true
}
