# The free Supabase plan pauses a project after a week without activity. This
# Worker calls puzzles-backend's keep_alive() every day. Cron triggers don't
# depend on GitHub activity, unlike a scheduled workflow, which GitHub turns
# off after 60 days without commits.

# The project's API address and publishable key, from supabase/.
data "tfe_outputs" "supabase" {
  workspace = "joclegg-supabase"
}

module "puzzles_keep_alive" {
  source     = "../modules/worker"
  account_id = local.account_id
  zone_id    = local.zone_id

  name      = "puzzles-keep-alive"
  file      = "${path.module}/workers/puzzles-keep-alive.js"
  schedules = ["17 6 * * *"]

  # The project URL and publishable key are public: every app ships them.
  bindings = [
    {
      type = "plain_text"
      name = "SUPABASE_URL"
      text = data.tfe_outputs.supabase.nonsensitive_values.api_url
    },
    {
      type = "plain_text"
      name = "SUPABASE_KEY"
      text = data.tfe_outputs.supabase.nonsensitive_values.publishable_key
    },
  ]
}

moved {
  from = cloudflare_workers_script.puzzles_keep_alive
  to   = module.puzzles_keep_alive.cloudflare_workers_script.this
}

moved {
  from = cloudflare_workers_cron_trigger.puzzles_keep_alive
  to   = module.puzzles_keep_alive.cloudflare_workers_cron_trigger.this[0]
}
