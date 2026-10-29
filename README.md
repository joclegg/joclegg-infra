# puzzles-infra

Terraform for the Puzzles apps. Each top-level folder is its own root, with its own state in an HCP Terraform workspace (organisation `joclegg`, execution mode Local), so every run happens in GitHub Actions.

- Pull requests: format check, validate and plan for each changed folder. The plans are in the run summary.
- Merges to `main`: plan, then apply, for each changed folder.
- The `terraform` check passes when every folder that ran passed.

## Folders

| Folder | Workspace | What it manages |
| --- | --- | --- |
| `hcp/` | `puzzles-hcp` | The HCP Terraform organisation and workspaces. `puzzles-hcp` was made by hand and imported; the organisation and it have `prevent_destroy`, because it holds this state. |
| `github/` | `puzzles-github` | Every repository on the account: settings, `main` protection and Pages, through `modules/repository`. All imported; repositories have `prevent_destroy` and are archived, not deleted, if removed. |

`modules/` will hold shared modules; a change there runs every folder.

## Secrets

Until Key Vault and SOPS are set up, secrets are GitHub Actions secrets in this repository:

| Secret | Used for |
| --- | --- |
| `TF_API_TOKEN` | HCP Terraform team token (owners): state and the `tfe` provider |
| `PUZZLES_INFRA_APP_KEY` | Private key of the `joclegg-puzzles-infra` GitHub App, for `github/`. Its Client ID is the `PUZZLES_INFRA_APP_CLIENT_ID` variable. |

## Running locally

```sh
terraform login   # once
cd hcp
terraform init
terraform plan
```

For `github/`, sign in with your own GitHub login: `GITHUB_TOKEN=$(gh auth token) terraform plan`.

Locally, only plan. Changes are applied by the workflow after merging.
