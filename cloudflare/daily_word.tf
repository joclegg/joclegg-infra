# Serves Five Letters' second daily word to puzzles-web, puzzles-android and
# puzzles-ios at https://puzzles-daily.joclegg.dev/word/<yyyy-mm-dd>. The
# Worker reads it from a public answers page and caches each day's word.

resource "cloudflare_workers_script" "puzzles_daily_word" {
  account_id         = local.account_id
  script_name        = "puzzles-daily-word"
  content            = file("${path.module}/workers/puzzles-daily-word.js")
  main_module        = "puzzles-daily-word.js"
  compatibility_date = "2026-10-01"
}

resource "cloudflare_workers_custom_domain" "puzzles_daily_word" {
  account_id = local.account_id
  zone_id    = local.zone_id
  hostname   = "puzzles-daily.joclegg.dev"
  service    = cloudflare_workers_script.puzzles_daily_word.script_name
}

output "puzzles_daily_word_url" {
  value = "https://${cloudflare_workers_custom_domain.puzzles_daily_word.hostname}/word/"
}
