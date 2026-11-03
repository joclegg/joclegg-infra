# puzzles-android's release workflow signs in as this account to publish to
# Google Play. It's invited in the Play Console by hand, with release
# permissions for the app: Play has no Terraform provider.
resource "google_service_account" "play_publisher" {
  account_id   = "play-publisher"
  display_name = "Google Play publishing (puzzles-android)"
}

# Only workflows running on puzzles-android's main branch, which is where
# releases are published from.
resource "google_service_account_iam_member" "play_publisher_github" {
  service_account_id = google_service_account.play_publisher.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/${local.pool_name}/subject/repo:joclegg/puzzles-android:ref:refs/heads/main"
}

output "workload_identity_provider" {
  description = "The provider's full resource name, for google-github-actions/auth."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "play_publisher_email" {
  value = google_service_account.play_publisher.email
}
