# joclegg-infra

Terraform for everything the joclegg account runs on: HCP Terraform, every GitHub repository, and the Puzzles apps' services. Each top-level folder is its own root, with its own state in an HCP Terraform workspace (organisation `joclegg`, execution mode Local), so every run happens in GitHub Actions.

- Pull requests: format check, validate and plan for each changed folder. The plans are in the run summary.
- Merges to `main`: plan, then apply, for each changed folder.
- Every Monday, and when run by hand: plan and apply every folder, which picks up the Azure secret rotation and shows drift.
- The `terraform` check passes when every folder that ran passed.

## Folders

| Folder | Workspace | What it manages |
| --- | --- | --- |
| `hcp/` | `joclegg-hcp` | The HCP Terraform organisation and workspaces. `joclegg-hcp` was made by hand and imported; the organisation and it have `prevent_destroy`, because it holds this state. |
| `azure/` | `joclegg-azure` | The `Puzzles` Microsoft Entra ID app registration, for "Sign in with Microsoft": personal and work accounts, the Supabase callback, the `email` and `xms_edov` claims, and a client secret replaced every 180 days. Signs in as `joclegg-infra-github`, which was made by hand with GitHub OIDC credentials and `Application.ReadWrite.OwnedBy`, made an owner of itself, and imported: its federated credentials and permissions are managed here too, but admin consent is granted by hand. |
| `cloudflare/` | `joclegg-cloudflare` | The `joclegg.dev` zone (imported), DNSSEC, always-HTTPS, minimum TLS 1.2, and its DNS records: Mailgun's records from `mailgun/`'s outputs, DMARC, and an SPF record saying the root domain sends no email. Also the `puzzles-keep-alive` Worker (`workers/`), whose daily cron trigger calls puzzles-backend's `keep_alive()` so the free Supabase project never pauses. The `puzzles-daily-word` Worker, which serves Five Letters' second daily word to the Puzzles apps at `puzzles-daily.joclegg.dev/word/<yyyy-mm-dd>`, with its Wordle number, read from a public answers page and cached a day. And the `joclegg-pages` Worker, which serves the CV at `joclegg.dev` and Puzzles at `puzzles.joclegg.dev` by fetching them from GitHub Pages, so their `joclegg.github.io` addresses keep working too. The registration (bought through Cloudflare Registrar; auto-renew and transfer lock) is set in the dashboard: the provider has no resource for it. |
| `github/` | `joclegg-github` | Every repository on the account: settings, `main` protection and Pages, through `modules/repository`. All imported; repositories have `prevent_destroy` and are archived, not deleted, if removed. |
| `mailgun/` | `joclegg-mailgun` | Sending email from `mg.joclegg.dev` through Mailgun (community provider `wgebis/mailgun`; there's no official one), and the SMTP login Supabase uses. Outputs the DNS records `cloudflare/` publishes. |
| `supabase/` | `joclegg-supabase` | The Puzzles Supabase project and its auth settings: site URL, redirect URLs, sign-ups, email sign-in (a magic link with a code), the Google provider (not its secret), the Azure provider (client ID and secret from `azure/`'s outputs), SMTP through Mailgun (from `mailgun/`'s outputs), and token lifetimes. Imported. The email subjects and templates are in `supabase/templates/`. Only the auth keys listed are managed; the database schema stays in puzzles-backend. |

`modules/` will hold shared modules; a change there runs every folder.

## Secrets

Every secret is a GitHub Actions secret in this repository, stored once. `github/secrets.tf` copies the ones other repositories need into them, so to change one, set it here and run the workflow (or merge any change to `github/`).

| Secret | Used for |
| --- | --- |
| `TF_API_TOKEN` | HCP Terraform team token (owners): state and the `tfe` provider |
| `REPO_DISPATCH_APP_KEY` | Private key of the `joclegg-repo-dispatch` GitHub App, installed on each repository that lists `submodules`, with Contents write. The Worker in `cloudflare/merge_webhook.tf` turns it into a 1-hour token to tell those repositories to move their submodules. Its Client ID is the `REPO_DISPATCH_APP_CLIENT_ID` variable. |
| `MAILGUN_API_KEY` | For `mailgun/`. |
| `CLOUDFLARE_API_TOKEN` | For `cloudflare/`: zone, zone settings, DNS and Workers Routes write on `joclegg.dev`, and Workers Scripts write on the account. Expires 29 October 2027. |
| `SUPABASE_ACCESS_TOKEN` | Used by `supabase/`, and copied to puzzles-backend for pushing migrations. |
| `PUZZLES_KEYSTORE_BASE64`, `PUZZLES_KEYSTORE_PASSWORD`, `PUZZLES_KEY_ALIAS`, `PUZZLES_KEY_PASSWORD` | The Android release keystore, base64-encoded, and its passwords. Copied to puzzles-android. Keep a copy outside GitHub: secrets can't be read back. |
| `INFRA_GITHUB_TOKEN` | Fine-grained token for `github/`: all repositories, with Actions, Administration, Contents, Environments, Pages, Secrets, Variables and Webhooks write. A GitHub App can't create repositories on a personal account, so this is a token. It expires after a year. |

## Running locally

```sh
terraform login   # once
cd hcp
terraform init
terraform plan
```

For `github/`, sign in with your own GitHub login: `GITHUB_TOKEN=$(gh auth token) terraform plan`. For `supabase/`, set `SUPABASE_ACCESS_TOKEN` to a Supabase access token.

Locally, only plan. Changes are applied by the workflow after merging.
