terraform {
  required_version = ">= 1.17"

  cloud {
    organization = "joclegg"

    workspaces {
      name = "joclegg-supabase"
    }
  }

  required_providers {
    supabase = {
      source  = "supabase/supabase"
      version = "~> 1.11"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.70"
    }
  }
}

# Signs in with SUPABASE_ACCESS_TOKEN.
provider "supabase" {}

# Reads azure/'s outputs. Signs in with TFE_TOKEN.
provider "tfe" {
  organization = "joclegg"
}
