# The free Supabase plan pauses a project after a week without activity. This
# Worker calls puzzles-backend's keep_alive() every day. Cron triggers don't
# depend on GitHub activity, unlike a scheduled workflow, which GitHub turns
# off after 60 days without commits.

locals {
  account_id = cloudflare_zone.joclegg_dev.account.id
}

resource "cloudflare_workers_script" "puzzles_keep_alive" {
  account_id         = local.account_id
  script_name        = "puzzles-keep-alive"
  content            = file("${path.module}/workers/puzzles-keep-alive.js")
  main_module        = "puzzles-keep-alive.js"
  compatibility_date = "2026-10-01"

  # The project URL and publishable key are public: both apps ship them.
  bindings = [
    {
      type = "plain_text"
      name = "SUPABASE_URL"
      text = "https://nrlmaucpuesfmvqhtupe.supabase.co"
    },
    {
      type = "plain_text"
      name = "SUPABASE_KEY"
      text = "sb_publishable_gQgbll0ElIbV41OtkvuXlQ_yUegn2hH"
    },
  ]
}

resource "cloudflare_workers_cron_trigger" "puzzles_keep_alive" {
  account_id  = local.account_id
  script_name = cloudflare_workers_script.puzzles_keep_alive.script_name
  schedules = [
    { cron = "17 6 * * *" },
  ]
}
