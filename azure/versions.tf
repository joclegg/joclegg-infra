terraform {
  required_version = ">= 1.17"

  cloud {
    organization = "joclegg"

    workspaces {
      name = "joclegg-azure"
    }
  }

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.10"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.14"
    }
  }
}

# Signs in as the joclegg-infra-github app registration, through GitHub's OIDC
# token: ARM_USE_OIDC, ARM_CLIENT_ID and ARM_TENANT_ID. It has
# Application.ReadWrite.OwnedBy, so it can only manage the apps it creates.
# That app was made by hand in the Azure portal.
provider "azuread" {}
