# Finishes "Sign in with GitHub" for actions-dashboard at
# actions-auth.joclegg.dev/token, adding the GitHub App's client secret.

variable "ACTIONS_DASHBOARD_APP_CLIENT_ID" {
  description = "Client ID of the actions-dashboard GitHub App."
  type        = string
}

variable "ACTIONS_DASHBOARD_APP_CLIENT_SECRET" {
  description = "Client secret of that app."
  type        = string
  sensitive   = true
}

module "actions_auth" {
  source     = "../modules/worker"
  account_id = local.account_id
  zone_id    = local.zone_id

  name      = "actions-auth"
  file      = "${path.module}/workers/actions-auth.js"
  hostnames = ["actions-auth.joclegg.dev"]

  bindings = [
    {
      type = "plain_text"
      name = "CLIENT_ID"
      text = var.ACTIONS_DASHBOARD_APP_CLIENT_ID
    },
    {
      type = "secret_text"
      name = "CLIENT_SECRET"
      text = var.ACTIONS_DASHBOARD_APP_CLIENT_SECRET
    },
  ]
}
