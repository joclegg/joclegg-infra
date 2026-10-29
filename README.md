# puzzles-infra

Terraform for the Puzzles apps. Each top-level folder is its own root, with its own state in an HCP Terraform workspace (organisation `joclegg`, execution mode Local), so every run happens in GitHub Actions.

- Pull requests: format check, validate and plan for each changed folder. The plans are in the run summary.
- Merges to `main`: plan, then apply, for each changed folder.
- The `terraform` check passes when every folder that ran passed.

## Folders

| Folder | Workspace | What it manages |
| --- | --- | --- |
| `hcp/` | `puzzles-hcp` | The HCP Terraform organisation and workspaces. `puzzles-hcp` was made by hand and imported; the organisation and it have `prevent_destroy`, because it holds this state. |
| `github/` | `puzzles-github` | Coming next. |

`modules/` will hold shared modules; a change there runs every folder.

## Secrets

Until Key Vault and SOPS are set up, secrets are GitHub Actions secrets in this repository:

| Secret | Used for |
| --- | --- |
| `TF_API_TOKEN` | HCP Terraform team token (owners): state and the `tfe` provider |

## Running locally

```sh
terraform login   # once
cd hcp
terraform init
terraform plan
```
