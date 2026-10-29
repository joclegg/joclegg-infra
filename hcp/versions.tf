terraform {
  required_version = ">= 1.17"

  cloud {
    organization = "joclegg"

    workspaces {
      name = "joclegg-hcp"
    }
  }

  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.70"
    }
  }
}

# Signs in with TFE_TOKEN, the same token that stores the state.
provider "tfe" {
  organization = "joclegg"
}
