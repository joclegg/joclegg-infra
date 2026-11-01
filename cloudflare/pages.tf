# joclegg.dev serves the CV and puzzles.joclegg.dev serves Puzzles, through a
# Worker that fetches them from GitHub Pages. GitHub's own custom domains
# would redirect joclegg.github.io/cv/ and joclegg.github.io/puzzles-web/ to
# the new addresses; this keeps both addresses serving. The sites stay as set
# in github/.

module "joclegg_pages" {
  source     = "../modules/worker"
  account_id = local.account_id
  zone_id    = local.zone_id

  name      = "joclegg-pages"
  file      = "${path.module}/workers/joclegg-pages.js"
  hostnames = ["joclegg.dev", "puzzles.joclegg.dev"]
}

moved {
  from = cloudflare_workers_script.joclegg_pages
  to   = module.joclegg_pages.cloudflare_workers_script.this
}

moved {
  from = cloudflare_workers_custom_domain.joclegg_pages
  to   = module.joclegg_pages.cloudflare_workers_custom_domain.this
}
