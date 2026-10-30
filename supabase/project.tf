# The Puzzles Supabase project and its auth settings. The project was made by
# hand and imported. The database schema stays in puzzles-backend.

locals {
  project_ref = "nrlmaucpuesfmvqhtupe"
}

# The Puzzles Microsoft Entra ID app, from azure/. Its client secret is
# replaced every 180 days, and the next run here picks up the new one.
data "tfe_outputs" "azure" {
  workspace = "joclegg-azure"
}

# The SMTP login for mg.joclegg.dev, from mailgun/.
data "tfe_outputs" "mailgun" {
  workspace = "joclegg-mailgun"
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
# it is. The Azure client secret comes from azure/. Not managed:
# - The Google client secret: Supabase never returns it, so it stays as set in
#   the dashboard.
# - Email subjects and templates: they were set in the dashboard while
#   Supabase's own sender was in use, which refuses changes through the API.
resource "supabase_settings" "puzzles" {
  project_ref = supabase_project.puzzles.id

  auth = jsonencode({
    site_url       = "https://joclegg.github.io/puzzles-web/"
    uri_allow_list = join(",", ["http://localhost:5173/**", "com.joclegg.puzzles://auth"])

    disable_signup                   = false
    external_anonymous_users_enabled = false
    mailer_autoconfirm               = false

    # Email sign-in (password, magic links, codes) is off: both apps sign in
    # with Google or Microsoft only, and Supabase's own email sender only
    # emails project members.
    external_email_enabled = false

    external_google_enabled   = true
    external_google_client_id = "173393208059-736edpatfv5vfdbvt8cm84lqujbp46im.apps.googleusercontent.com"

    # "Sign in with Microsoft", for personal and work accounts.
    external_azure_enabled   = true
    external_azure_client_id = data.tfe_outputs.azure.nonsensitive_values.puzzles_client_id
    external_azure_secret    = data.tfe_outputs.azure.values.puzzles_client_secret
    external_azure_url       = "https://login.microsoftonline.com/common"

    # Auth emails go out through Mailgun, from mg.joclegg.dev, instead of
    # Supabase's own sender, which only emails project members.
    smtp_host        = data.tfe_outputs.mailgun.nonsensitive_values.smtp_host
    smtp_port        = "587"
    smtp_user        = data.tfe_outputs.mailgun.nonsensitive_values.smtp_user
    smtp_pass        = data.tfe_outputs.mailgun.values.smtp_password
    smtp_admin_email = "no-reply@mg.joclegg.dev"
    smtp_sender_name = "Puzzles"

    jwt_exp                               = 3600
    refresh_token_rotation_enabled        = true
    security_refresh_token_reuse_interval = 10
  })
}
