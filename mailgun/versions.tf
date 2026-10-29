terraform {
  required_version = ">= 1.17"

  cloud {
    organization = "joclegg"

    workspaces {
      name = "joclegg-mailgun"
    }
  }

  required_providers {
    # A community provider: Mailgun has no official one.
    mailgun = {
      source  = "wgebis/mailgun"
      version = "~> 0.10"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

# Signs in with MAILGUN_API_KEY.
provider "mailgun" {}
