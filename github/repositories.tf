# Every repository on the joclegg account. The first 8 were made by hand and
# imported; add a new one here and Terraform creates it.

locals {
  repositories = {
    "puzzles" = {
      description = "Puzzles: the Android app, the website and their shared puzzle data, as submodules"
    }
    "puzzles-android" = {
      description            = "Offline puzzle games for Android: sudoku and solitaire"
      delete_branch_on_merge = true
      required_checks = [
        "Lint, unit tests, build",
        "Maestro e2e (part 1 of 3)",
        "Maestro e2e (part 2 of 3)",
        "Maestro e2e (part 3 of 3)",
      ]
    }
    "puzzles-ios" = {
      description = "iOS version of Puzzles: eight offline puzzle games"
    }
    "puzzles-web" = {
      description     = "Web version of Puzzles: eight offline puzzle games in React and TypeScript"
      required_checks = ["build-and-test"]
      pages           = { build_type = "workflow" }
    }
    "puzzles-data" = {
      description = "Puzzle banks and word lists shared by puzzles-android and puzzles-web"
    }
    "puzzles-backend" = {
      description     = "Supabase backend for Puzzles score sync"
      required_checks = ["build-and-test"]
    }
    "joclegg-infra" = {
      description     = "Terraform for everything the joclegg account runs on"
      required_checks = ["terraform"]
    }
    "cv" = {
      homepage_url           = "https://joclegg.github.io/cv/"
      delete_branch_on_merge = true
      secret_scanning        = false
      required_checks        = ["build-and-test"]
      pages                  = { build_type = "workflow" }
    }
    "joclegg.github.io" = {
      description = "Root of joclegg.github.io"
      pages       = { build_type = "legacy" }
    }
  }
}

module "repository" {
  source   = "../modules/repository"
  for_each = local.repositories

  name                   = each.key
  description            = lookup(each.value, "description", null)
  homepage_url           = lookup(each.value, "homepage_url", null)
  delete_branch_on_merge = lookup(each.value, "delete_branch_on_merge", false)
  secret_scanning        = lookup(each.value, "secret_scanning", true)
  required_checks        = lookup(each.value, "required_checks", null)
  pages                  = lookup(each.value, "pages", null)
}

# puzzles-infra was renamed joclegg-infra, as it manages the whole account.
# GitHub redirects the old name.
moved {
  from = module.repository["puzzles-infra"]
  to   = module.repository["joclegg-infra"]
}
