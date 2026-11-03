locals {
  project_id     = "puzzles-513020"
  project_number = "173393208059"
  pool_name      = "projects/${local.project_number}/locations/global/workloadIdentityPools/github"

  apis = toset([
    "androidpublisher.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "serviceusage.googleapis.com",
    "sts.googleapis.com",
  ])

  terraform_roles = toset([
    "roles/iam.serviceAccountAdmin",
    "roles/iam.workloadIdentityPoolAdmin",
    "roles/resourcemanager.projectIamAdmin",
    "roles/serviceusage.serviceUsageAdmin",
  ])
}

# Everything in this file was made once by hand in Cloud Shell, so Actions had
# an account to sign in as, and is imported here.

import {
  for_each = local.apis
  to       = google_project_service.this[each.value]
  id       = "${local.project_id}/${each.value}"
}

# Turning an API off would break whatever uses it, so removing one from the
# list only stops managing it.
resource "google_project_service" "this" {
  for_each = local.apis

  service            = each.value
  disable_on_destroy = false
}

import {
  to = google_iam_workload_identity_pool.github
  id = local.pool_name
}

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github"
  display_name              = "GitHub Actions"
}

import {
  to = google_iam_workload_identity_pool_provider.github
  id = "${local.pool_name}/providers/github"
}

# Only tokens from joclegg's repositories are accepted; each service account
# then says which repository, or branch, may use it.
resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  attribute_condition                = "assertion.repository_owner == 'joclegg'"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

import {
  to = google_service_account.terraform
  id = "projects/${local.project_id}/serviceAccounts/terraform@${local.project_id}.iam.gserviceaccount.com"
}

resource "google_service_account" "terraform" {
  account_id   = "terraform"
  display_name = "Terraform (joclegg-infra)"
}

import {
  for_each = local.terraform_roles
  to       = google_project_iam_member.terraform[each.value]
  id       = "${local.project_id} ${each.value} serviceAccount:${google_service_account.terraform.email}"
}

# Non-authoritative, so roles granted to anyone else in the project are left
# alone.
resource "google_project_iam_member" "terraform" {
  for_each = local.terraform_roles

  project = local.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.terraform.email}"
}

import {
  to = google_service_account_iam_member.terraform_github
  id = "${google_service_account.terraform.id} roles/iam.workloadIdentityUser principalSet://iam.googleapis.com/${local.pool_name}/attribute.repository/joclegg/joclegg-infra"
}

resource "google_service_account_iam_member" "terraform_github" {
  service_account_id = google_service_account.terraform.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${local.pool_name}/attribute.repository/joclegg/joclegg-infra"
}
