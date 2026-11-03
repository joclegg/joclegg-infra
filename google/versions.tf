terraform {
  required_version = ">= 1.17"

  cloud {
    organization = "joclegg"

    workspaces {
      name = "joclegg-google"
    }
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.9"
    }
  }
}

# Signs in as the terraform service account through Workload Identity
# Federation: the workflow's google-github-actions/auth step trades GitHub's
# OIDC token for its credentials. That account and the pool it trusts were
# made by hand in Cloud Shell and imported in bootstrap.tf.
provider "google" {
  project = local.project_id
}
