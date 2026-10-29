# The Puzzles Supabase project and its auth settings. The project was made by
# hand and imported. The database schema stays in puzzles-backend.

locals {
  project_ref = "nrlmaucpuesfmvqhtupe"

}

resource "supabase_project" "puzzles" {
  organization_id = "xnvkcupvhffhdgwtpyvu"
  name            = "puzzles"
  region          = "eu-west-3"

  # Required by the provider but never read back. ignore_changes keeps
  # Terraform from ever setting it, so the real password is left alone.
  database_password = "unused"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [database_password]
  }
}

# Only the keys listed here are managed; every other auth setting is left as
# it is. Not managed:
# - The Google client secret: Supabase never returns it, so it stays as set in
#   the dashboard.
# - Email subjects and templates: on the free tier with Supabase's own email
#   sender, the API refuses any change to them, even to the same text.
resource "supabase_settings" "puzzles" {
  project_ref = supabase_project.puzzles.id

  auth = jsonencode({
    site_url       = "https://joclegg.github.io/puzzles-web/"
    uri_allow_list = join(",", ["http://localhost:5173/**", "com.joclegg.puzzles://auth"])

    disable_signup                   = false
    external_anonymous_users_enabled = false
    external_email_enabled           = true
    mailer_autoconfirm               = false

    external_google_enabled   = true
    external_google_client_id = "173393208059-736edpatfv5vfdbvt8cm84lqujbp46im.apps.googleusercontent.com"

    jwt_exp                               = 3600
    refresh_token_rotation_enabled        = true
    security_refresh_token_reuse_interval = 10
  })
}
