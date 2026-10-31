terraform {
  required_version = ">= 1.17"

  cloud {
    organization = "joclegg"

    workspaces {
      name = "joclegg-cloudflare"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.28"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.70"
    }
  }
}

# Signs in with CLOUDFLARE_API_TOKEN: zone, zone settings, DNS and Workers
# Routes write on joclegg.dev, and Workers Scripts write on the account.
provider "cloudflare" {}

# Reads mailgun/'s outputs. Signs in with TFE_TOKEN.
provider "tfe" {
  organization = "joclegg"
}
