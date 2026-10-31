# Each submodule tells the Worker in cloudflare/ when it's pushed to, and the
# Worker tells the repository that lists it. A repository can be a submodule of
# several. Each one listing submodules needs the joclegg-puzzles-dispatch GitHub
# App installed and a workflow that handles submodule-merged.

data "tfe_outputs" "cloudflare" {
  workspace = "joclegg-cloudflare"
}

locals {
  submodule_webhooks = merge([
    for parent, repository in local.repositories : {
      for submodule in lookup(repository, "submodules", []) :
      "${parent}/${submodule}" => { parent = parent, submodule = submodule }
    }
  ]...)
}

resource "github_repository_webhook" "merge" {
  for_each = local.submodule_webhooks

  repository = module.repository[each.value.submodule].name
  events     = ["push"]

  configuration {
    url          = "${data.tfe_outputs.cloudflare.nonsensitive_values.merge_webhook_url}${each.value.parent}"
    content_type = "json"
    secret       = data.tfe_outputs.cloudflare.values.merge_webhook_secret
  }
}
