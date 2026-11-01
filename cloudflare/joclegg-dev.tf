# joclegg.dev: bought through Cloudflare Registrar, which made the zone, then
# imported. The registration itself (auto-renew, transfer lock) is set in the
# dashboard: the provider has no resource for it.

import {
  to = cloudflare_zone.joclegg_dev
  id = "a93c1ccba976649debf060219b51c786"
}

resource "cloudflare_zone" "joclegg_dev" {
  account = {
    id = "c23f0b5d99102cd197ffad7dbafd0a73"
  }
  name = "joclegg.dev"
  type = "full"

  lifecycle {
    prevent_destroy = true
  }
}

# Cloudflare is the registrar, so it publishes the DS record at the .dev
# registry itself.
resource "cloudflare_zone_dnssec" "joclegg_dev" {
  zone_id = cloudflare_zone.joclegg_dev.id
  status  = "active"
}

resource "cloudflare_zone_setting" "always_use_https" {
  zone_id    = cloudflare_zone.joclegg_dev.id
  setting_id = "always_use_https"
  value      = "on"
}

resource "cloudflare_zone_setting" "min_tls_version" {
  zone_id    = cloudflare_zone.joclegg_dev.id
  setting_id = "min_tls_version"
  value      = "1.2"
}

# Mailgun's records for mg.joclegg.dev: SPF, DKIM, the tracking CNAME and MX.
data "tfe_outputs" "mailgun" {
  workspace = "joclegg-mailgun"
}

locals {
  account_id = cloudflare_zone.joclegg_dev.account.id
  zone_id    = cloudflare_zone.joclegg_dev.id

  # Keyed by type and name, plus the content for MX, which has two records on
  # the same name.
  mailgun_records = {
    for r in data.tfe_outputs.mailgun.nonsensitive_values.dns_records :
    join(" ", compact([r.type, r.name, r.type == "MX" ? r.content : ""])) => r
  }
}

resource "cloudflare_dns_record" "mailgun" {
  for_each = local.mailgun_records

  zone_id  = local.zone_id
  type     = each.value.type
  name     = each.value.name
  content  = each.value.content
  priority = each.value.priority
  ttl      = 1
  proxied  = false
  comment  = "Mailgun, from mailgun/ in joclegg-infra"
}

# Only mg.joclegg.dev sends email. Receivers quarantine anything else that
# claims to be from joclegg.dev, and joclegg.dev itself sends nothing.
resource "cloudflare_dns_record" "dmarc" {
  zone_id = local.zone_id
  type    = "TXT"
  name    = "_dmarc.joclegg.dev"
  content = "\"v=DMARC1; p=quarantine; adkim=r; aspf=r\""
  ttl     = 1
  comment = "DMARC, from cloudflare/ in joclegg-infra"
}

resource "cloudflare_dns_record" "spf_root" {
  zone_id = local.zone_id
  type    = "TXT"
  name    = "joclegg.dev"
  content = "\"v=spf1 -all\""
  ttl     = 1
  comment = "joclegg.dev sends no email; mg.joclegg.dev has its own SPF"
}
