# The Puzzles Supabase project and its auth settings. The project was made by
# hand and imported. The database schema stays in puzzles-backend.

locals {
  project_ref = "nrlmaucpuesfmvqhtupe"

  # Email subjects; each one's body is templates/<name>.html.
  email_subjects = {
    confirmation                       = "Confirm your email address"
    email_change                       = "Confirm your new email address"
    email_changed_notification         = "Your email address was changed"
    identity_linked_notification       = "A new sign-in method was linked to your account"
    identity_unlinked_notification     = "A sign-in method was removed from your account"
    invite                             = "You've been invited"
    magic_link                         = "Your sign-in link"
    mfa_factor_enrolled_notification   = "A new verification method was added to your account"
    mfa_factor_unenrolled_notification = "A verification method was removed from your account"
    password_changed_notification      = "Your password was changed"
    phone_changed_notification         = "Your phone number was changed"
    reauthentication                   = "{{ .Token }} is your verification code"
    recovery                           = "Reset your password"
  }
}

import {
  to = supabase_project.puzzles
  id = local.project_ref
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

import {
  to = supabase_settings.puzzles
  id = local.project_ref
}

# Only the keys listed here are managed; every other auth setting is left as
# it is. The Google client secret isn't here: Supabase never returns it, so it
# stays as set in the dashboard.
resource "supabase_settings" "puzzles" {
  project_ref = supabase_project.puzzles.id

  auth = jsonencode(merge(
    {
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
    },
    { for name, subject in local.email_subjects : "mailer_subjects_${name}" => subject },
    { for name, subject in local.email_subjects : "mailer_templates_${name}_content" => file("${path.module}/templates/${name}.html") },
  ))
}
