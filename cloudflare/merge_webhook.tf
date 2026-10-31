# Tells a parent repository to move its submodules when one of their main
# branches moves. github/webhooks.tf points each webhook here and reads the
# secret from this workspace's outputs.

variable "REPO_DISPATCH_APP_CLIENT_ID" {
  description = "Client ID of the joclegg-repo-dispatch GitHub App."
  type        = string
}

variable "REPO_DISPATCH_APP_KEY" {
  description = "Private key of that app, which the Worker turns into a 1-hour token."
  type        = string
  sensitive   = true
}

resource "random_password" "merge_webhook_secret" {
  length  = 40
  special = false
}

resource "cloudflare_workers_script" "merge_webhook" {
  account_id         = local.account_id
  script_name        = "joclegg-merge-webhook"
  content            = file("${path.module}/workers/merge-webhook.js")
  main_module        = "merge-webhook.js"
  compatibility_date = "2026-10-01"

  bindings = [
    {
      type = "plain_text"
      name = "APP_CLIENT_ID"
      text = var.REPO_DISPATCH_APP_CLIENT_ID
    },
    {
      type = "secret_text"
      name = "APP_PRIVATE_KEY"
      text = var.REPO_DISPATCH_APP_KEY
    },
    {
      type = "secret_text"
      name = "WEBHOOK_SECRET"
      text = random_password.merge_webhook_secret.result
    },
  ]
}

resource "cloudflare_workers_custom_domain" "merge_webhook" {
  account_id = local.account_id
  zone_id    = local.zone_id
  hostname   = "hooks.joclegg.dev"
  service    = cloudflare_workers_script.merge_webhook.script_name
}

output "merge_webhook_url" {
  value = "https://${cloudflare_workers_custom_domain.merge_webhook.hostname}/"
}

output "merge_webhook_secret" {
  value     = random_password.merge_webhook_secret.result
  sensitive = true
}
