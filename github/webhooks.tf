# Each repository with a parent tells the Worker in cloudflare/ when it's pushed
# to, and the Worker tells the parent. The parent needs the
# joclegg-puzzles-dispatch GitHub App installed and a workflow that handles
# submodule-merged.

data "tfe_outputs" "cloudflare" {
  workspace = "joclegg-cloudflare"
}

locals {
  parents = {
    for name, repository in local.repositories : name => repository.parent
    if lookup(repository, "parent", null) != null
  }
}

resource "github_repository_webhook" "merge" {
  for_each = local.parents

  repository = module.repository[each.key].name
  events     = ["push"]

  configuration {
    url          = "${data.tfe_outputs.cloudflare.nonsensitive_values.merge_webhook_url}${each.value}"
    content_type = "json"
    secret       = data.tfe_outputs.cloudflare.values.merge_webhook_secret
  }
}
