# DNS for joclegg.dev. The domain was bought through Cloudflare Registrar,
# which made the zone; this only manages its records.

data "cloudflare_zone" "joclegg_dev" {
  filter = {
    name = "joclegg.dev"
  }
}

# Mailgun's records for mg.joclegg.dev: SPF, DKIM, the tracking CNAME and MX.
data "tfe_outputs" "mailgun" {
  workspace = "joclegg-mailgun"
}

locals {
  zone_id = data.cloudflare_zone.joclegg_dev.zone_id

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
