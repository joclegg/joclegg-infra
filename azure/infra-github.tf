# joclegg-infra-github: the app registration Terraform signs in as, from
# GitHub Actions in joclegg/joclegg-infra. Made by hand in the Azure portal,
# made an owner of itself (so Application.ReadWrite.OwnedBy reaches it), and
# imported.
#
# Take care: a broken federated credential stops CI signing in, so the next
# apply couldn't fix it. Fix it by hand in the portal as a Global Administrator.
# Granting admin consent for its Graph permissions is also by hand.

locals {
  infra_github_object_id = "a850ba81-a68e-4b42-ace8-4d4f7b0c9cda"

  # Its service principal: the identity Terraform runs as in CI. Written out,
  # not read from azuread_client_config, so a local plan signed in as a person
  # shows the same owners as CI.
  infra_github_sp_object_id = "b506ca93-51ce-4772-a634-5199e62b729e"

  # GitHub's OIDC subjects use immutable IDs: joclegg is 30325082 and
  # joclegg-infra is 1438917348.
  infra_github_subject_prefix = "repo:joclegg@30325082/joclegg-infra@1438917348"
}

import {
  to = azuread_application.infra_github
  id = "/applications/${local.infra_github_object_id}"
}

resource "azuread_application" "infra_github" {
  display_name     = "joclegg-infra-github"
  sign_in_audience = "AzureADMyOrg"
  owners           = [local.infra_github_sp_object_id]

  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"]

    resource_access {
      id   = data.azuread_service_principal.msgraph.oauth2_permission_scope_ids["User.Read"]
      type = "Scope"
    }

    # Create and manage only the app registrations it owns.
    resource_access {
      id   = data.azuread_service_principal.msgraph.app_role_ids["Application.ReadWrite.OwnedBy"]
      type = "Role"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

locals {
  infra_github_credentials = {
    main = {
      id      = "a25acc95-0d51-4398-8f44-4e97d7c50204"
      subject = "${local.infra_github_subject_prefix}:ref:refs/heads/main"
    }
    pull-requests = {
      id      = "16856c8f-93dc-43d2-ad4a-199295903d27"
      subject = "${local.infra_github_subject_prefix}:pull_request"
    }
  }
}

import {
  for_each = local.infra_github_credentials
  to       = azuread_application_federated_identity_credential.infra_github[each.key]
  id       = "${local.infra_github_object_id}/federatedIdentityCredential/${each.value.id}"
}

resource "azuread_application_federated_identity_credential" "infra_github" {
  for_each = local.infra_github_credentials

  application_id = azuread_application.infra_github.id
  display_name   = each.key
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = each.value.subject
  audiences      = ["api://AzureADTokenExchange"]

  lifecycle {
    prevent_destroy = true
  }
}
