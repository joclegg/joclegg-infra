# AGENTS.md

Terraform for everything the joclegg account runs on. See `README.md` for what each folder manages and for every secret.

## Stack

- Terraform, with state in HCP Terraform (organisation `joclegg`, execution mode Local)
- GitHub Actions runs every plan and apply
- Cloudflare Workers in `cloudflare/workers/`, as plain JavaScript

## Commands

Run these in a folder, such as `github/`:

- `terraform fmt -recursive`: format
- `terraform init -backend=false`, then `terraform validate`: check without touching state
- `terraform plan`: see `README.md` for signing in

## Rules

### General

- MUST keep `terraform fmt -check -recursive` and `terraform validate` passing in every folder.
- MUST only plan locally. MUST NOT run `terraform apply` by hand: merging to `main` applies, as `README.md` describes.
- MUST read the pull request's plan before asking for a merge, and call out anything destroyed or replaced.
- MUST commit `.terraform.lock.hcl` with Linux and macOS hashes when providers change: `terraform providers lock -platform=linux_amd64 -platform=darwin_arm64`.

### Folders

- MUST give each new top-level folder a `versions.tf`, and its workspace in `hcp/hcp.tf`.
- MUST pass values between folders with outputs read through `tfe_outputs`, never by copying them.
- MUST add the folder that writes an output first, in a pull request before the one that reads it, because a plan can't read an output that hasn't been applied.
- MUST NOT make folders read each other's outputs in a cycle.

### Repositories

- MUST add every repository to `github/repositories.tf`.
- MUST put settings every repository shares in `modules/repository`, and give a repository only what truly differs.
- MUST list a repository's submodules under its `submodules`, so each gets a webhook through `github/webhooks.tf`.
- MUST NOT remove `prevent_destroy` from a repository or the HCP resources.

### Secrets

- MUST store each secret once, as an Actions secret here, and pass it to only the folder that uses it in `.github/workflows/terraform.yml`.
- MUST add each new secret to `README.md`.
- MUST NOT commit secret values or print them in outputs without `sensitive = true`.

### Moving and importing

- MUST use `moved` blocks when renaming or moving a resource, so it isn't destroyed and recreated.
- MUST use `import` blocks for anything made by hand.
