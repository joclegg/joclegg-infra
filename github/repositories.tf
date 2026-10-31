# Every repository on the joclegg account. The first 8 were made by hand and
# imported; add a new one here and Terraform creates it. A repository with a
# parent is one of that repository's submodules: see webhooks.tf.

locals {
  repositories = {
    "puzzles" = {
      submodules = [
        "joclegg-infra",
        "puzzles-android",
        "puzzles-backend",
        "puzzles-data",
        "puzzles-ios",
        "puzzles-web",
      ]
      description = "Puzzles: the Android app, the website and their shared puzzle data, as submodules"
    }
    "puzzles-android" = {
      parent      = "puzzles"
      description = "Offline puzzle games for Android: sudoku and solitaire"
      required_checks = [
        "Lint, unit tests, build",
        "Maestro e2e (part 1 of 3)",
        "Maestro e2e (part 2 of 3)",
        "Maestro e2e (part 3 of 3)",
      ]
    }
    "puzzles-ios" = {
      parent      = "puzzles"
      description = "iOS version of Puzzles: eight offline puzzle games"
    }
    "puzzles-web" = {
      parent          = "puzzles"
      description     = "Web version of Puzzles: eight offline puzzle games in React and TypeScript"
      required_checks = ["build-and-test"]
      pages           = { build_type = "workflow" }
    }
    "puzzles-data" = {
      parent      = "puzzles"
      description = "Puzzle banks and word lists shared by puzzles-android and puzzles-web"
      # The apps download new banks from https://joclegg.github.io/puzzles-data/
      # so new puzzles don't need an app release.
      pages = { build_type = "workflow" }
    }
    "puzzles-backend" = {
      parent          = "puzzles"
      description     = "Supabase backend for Puzzles score sync"
      required_checks = ["build-and-test"]
    }
    "joclegg-infra" = {
      parent          = "puzzles"
      description     = "Terraform for everything the joclegg account runs on"
      required_checks = ["terraform"]
    }
    "cv" = {
      homepage_url    = "https://joclegg.github.io/cv/"
      required_checks = ["build-and-test"]
      pages           = { build_type = "workflow" }
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

  name            = each.key
  description     = lookup(each.value, "description", null)
  homepage_url    = lookup(each.value, "homepage_url", null)
  required_checks = lookup(each.value, "required_checks", null)
  pages           = lookup(each.value, "pages", null)
}

# puzzles-infra was renamed joclegg-infra, as it manages the whole account.
# GitHub redirects the old name.
moved {
  from = module.repository["puzzles-infra"]
  to   = module.repository["joclegg-infra"]
}
