# joclegg-infra

Terraform for everything the joclegg account runs on: HCP Terraform, every GitHub repository, and the Puzzles apps' services. Each top-level folder is its own root, with its own state in an HCP Terraform workspace (organisation `joclegg`, execution mode Local), so every run happens in GitHub Actions.

- Pull requests: format check, validate and plan for each changed folder. The plans are in the run summary.
- Merges to `main`: plan, then apply, for each changed folder.
- The `terraform` check passes when every folder that ran passed.

## Folders

| Folder | Workspace | What it manages |
| --- | --- | --- |
| `hcp/` | `joclegg-hcp` | The HCP Terraform organisation and workspaces. `joclegg-hcp` was made by hand and imported; the organisation and it have `prevent_destroy`, because it holds this state. |
| `github/` | `joclegg-github` | Every repository on the account: settings, `main` protection and Pages, through `modules/repository`. All imported; repositories have `prevent_destroy` and are archived, not deleted, if removed. |

`modules/` will hold shared modules; a change there runs every folder.

## Secrets

Every secret is a GitHub Actions secret in this repository, stored once. `github/secrets.tf` copies the ones other repositories need into them, so to change one, set it here and run the workflow (or merge any change to `github/`).

| Secret | Used for |
| --- | --- |
| `TF_API_TOKEN` | HCP Terraform team token (owners): state and the `tfe` provider |
| `PUZZLES_DISPATCH_APP_KEY` | Private key of the `joclegg-puzzles-dispatch` GitHub App, installed only on `joclegg/puzzles` with Contents write. `notify-puzzles.yml` turns it into a 1-hour token to tell `joclegg/puzzles` to move its submodules after each merge. Its Client ID is the `PUZZLES_DISPATCH_APP_CLIENT_ID` variable. Both are copied to puzzles-android, puzzles-web, puzzles-data and puzzles-backend. |
| `SUPABASE_ACCESS_TOKEN` | Copied to puzzles-backend, for pushing migrations. |
| `PUZZLES_KEYSTORE_BASE64`, `PUZZLES_KEYSTORE_PASSWORD`, `PUZZLES_KEY_ALIAS`, `PUZZLES_KEY_PASSWORD` | The Android release keystore, base64-encoded, and its passwords. Copied to puzzles-android. Keep a copy outside GitHub: secrets can't be read back. |
| `PUZZLES_GITHUB_TOKEN` | Fine-grained token for `github/`: all repositories, with Actions, Administration, Contents, Environments, Pages, Secrets and Variables write. A GitHub App can't create repositories on a personal account, so this is a token. It expires after a year. |

## Running locally

```sh
terraform login   # once
cd hcp
terraform init
terraform plan
```

For `github/`, sign in with your own GitHub login: `GITHUB_TOKEN=$(gh auth token) terraform plan`.

Locally, only plan. Changes are applied by the workflow after merging.
