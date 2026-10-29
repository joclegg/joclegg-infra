terraform {
  required_version = ">= 1.17"

  cloud {
    organization = "joclegg"

    workspaces {
      name = "puzzles-github"
    }
  }

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.13"
    }
  }
}

# Signs in with GITHUB_TOKEN: in CI the PUZZLES_GITHUB_TOKEN secret, locally
# `gh auth token`.
provider "github" {
  owner = "joclegg"
}
