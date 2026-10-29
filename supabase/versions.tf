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
  }
}

# Signs in with SUPABASE_ACCESS_TOKEN.
provider "supabase" {}
