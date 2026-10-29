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

# Signs in with GITHUB_TOKEN: in CI a 1-hour token from the puzzles-infra GitHub
# App, locally `gh auth token`.
provider "github" {
  owner = "joclegg"
}
