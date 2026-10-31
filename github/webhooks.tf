# Each submodule of joclegg/puzzles tells the Worker in cloudflare/ when it's
# pushed to. The Worker moves the submodules.

data "tfe_outputs" "cloudflare" {
  workspace = "joclegg-cloudflare"
}

locals {
  merge_webhook_repositories = toset([
    "joclegg-infra",
    "puzzles-android",
    "puzzles-backend",
    "puzzles-data",
    "puzzles-ios",
    "puzzles-web",
  ])
}

resource "github_repository_webhook" "merge" {
  for_each = local.merge_webhook_repositories

  repository = module.repository[each.key].name
  events     = ["push"]

  configuration {
    url          = data.tfe_outputs.cloudflare.nonsensitive_values.merge_webhook_url
    content_type = "json"
    secret       = data.tfe_outputs.cloudflare.values.merge_webhook_secret
  }
}
