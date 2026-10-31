terraform {
  required_version = ">= 1.17"

  cloud {
    organization = "joclegg"

    workspaces {
      name = "joclegg-github"
    }
  }

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.13"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.70"
    }
  }
}

# Signs in with GITHUB_TOKEN: in CI the INFRA_GITHUB_TOKEN secret, locally
# `gh auth token`.
provider "github" {
  owner = "joclegg"
}

# Reads cloudflare/'s outputs. Signs in with TFE_TOKEN.
provider "tfe" {
  organization = "joclegg"
}
