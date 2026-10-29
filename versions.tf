terraform {
  required_version = ">= 1.17"

  cloud {
    organization = "joclegg"

    workspaces {
      name = "puzzles"
    }
  }

  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.70"
    }
  }
}

# Signs in with TF_TOKEN_app_terraform_io, the same token that stores the state.
provider "tfe" {
  organization = "joclegg"
}
