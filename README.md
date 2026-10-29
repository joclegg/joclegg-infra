# puzzles-infra

Terraform for the Puzzles apps. State lives in HCP Terraform (organisation `joclegg`, workspace `puzzles`, execution mode Local), so every run happens in GitHub Actions.

- Pull requests: format check, validate and plan. The plan is in the run summary.
- Merges to `main`: plan, then apply.

## What's managed

- `hcp.tf`: the HCP Terraform organisation and workspace, imported. Both have `prevent_destroy`, because the workspace holds this state.

## Secrets

Until Key Vault and SOPS are set up, secrets are GitHub Actions secrets in this repository:

| Secret | Used for |
| --- | --- |
| `TF_API_TOKEN` | HCP Terraform team token (owners): state and the `tfe` provider |

## Running locally

```sh
terraform login   # once
terraform init
terraform plan
```
