# joclegg.dev serves the CV and puzzles.joclegg.dev serves Puzzles, through a
# Worker that fetches them from GitHub Pages. GitHub's own custom domains
# would redirect joclegg.github.io/cv/ and joclegg.github.io/puzzles-web/ to
# the new addresses; this keeps both addresses serving. The sites stay as set
# in github/.

locals {
  pages_hostnames = toset(["joclegg.dev", "puzzles.joclegg.dev"])
}

resource "cloudflare_workers_script" "joclegg_pages" {
  account_id         = local.account_id
  script_name        = "joclegg-pages"
  content            = file("${path.module}/workers/joclegg-pages.js")
  main_module        = "joclegg-pages.js"
  compatibility_date = "2026-10-01"
}

# Each one makes the hostname's DNS record and certificate.
resource "cloudflare_workers_custom_domain" "joclegg_pages" {
  for_each = local.pages_hostnames

  account_id = local.account_id
  zone_id    = local.zone_id
  hostname   = each.value
  service    = cloudflare_workers_script.joclegg_pages.script_name
}
