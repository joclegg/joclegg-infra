# Serves Five Letters' second daily word to puzzles-web, puzzles-android and
# puzzles-ios at https://puzzles-daily.joclegg.dev/word/<yyyy-mm-dd>. The
# Worker reads it from a public answers page and caches each day's word.

module "puzzles_daily_word" {
  source     = "../modules/worker"
  account_id = local.account_id
  zone_id    = local.zone_id

  name      = "puzzles-daily-word"
  file      = "${path.module}/workers/puzzles-daily-word.js"
  hostnames = ["puzzles-daily.joclegg.dev"]
}

moved {
  from = cloudflare_workers_script.puzzles_daily_word
  to   = module.puzzles_daily_word.cloudflare_workers_script.this
}

moved {
  from = cloudflare_workers_custom_domain.puzzles_daily_word
  to   = module.puzzles_daily_word.cloudflare_workers_custom_domain.this["puzzles-daily.joclegg.dev"]
}

output "puzzles_daily_word_url" {
  value = "https://${one(module.puzzles_daily_word.hostnames)}/word/"
}
