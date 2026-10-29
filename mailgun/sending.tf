# Sending email from mg.joclegg.dev through Mailgun, for Supabase's auth
# emails. cloudflare/ publishes the DNS records from this workspace's outputs,
# and supabase/ reads the SMTP login.

locals {
  # US: where the Mailgun account was made.
  region = "us"
}

resource "mailgun_domain" "mg" {
  name          = "mg.joclegg.dev"
  region        = local.region
  dkim_key_size = 2048
  spam_action   = "disabled"

  # Auth emails need neither, and tracking rewrites the sign-in links.
  click_tracking = false
  open_tracking  = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "random_password" "supabase_smtp" {
  length  = 32
  special = false
}

resource "mailgun_domain_credential" "supabase" {
  domain   = mailgun_domain.mg.name
  region   = local.region
  login    = "supabase"
  password = random_password.supabase_smtp.result
}

output "dns_records" {
  description = "The records Mailgun needs on joclegg.dev: SPF, DKIM and the tracking CNAME for sending, and MX on mg.joclegg.dev for bounces."
  value = concat(
    [
      for r in mailgun_domain.mg.sending_records_set : {
        type     = r.record_type
        name     = r.name
        content  = r.value
        priority = null
      }
    ],
    [
      for r in mailgun_domain.mg.receiving_records_set : {
        type     = r.record_type
        name     = mailgun_domain.mg.name
        content  = r.value
        priority = tonumber(r.priority)
      }
    ],
  )
}

output "smtp_host" {
  value = "smtp.mailgun.org"
}

output "smtp_user" {
  value = "${mailgun_domain_credential.supabase.login}@${mailgun_domain.mg.name}"
}

output "smtp_password" {
  value     = random_password.supabase_smtp.result
  sensitive = true
}
