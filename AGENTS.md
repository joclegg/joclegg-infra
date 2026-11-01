# AGENTS.md

## Structure

Terraform for everything the joclegg account runs on. Each top-level folder with a `versions.tf` is its own root, with its own HCP Terraform workspace (`joclegg-<folder>`, local execution), planned and applied by GitHub Actions.

| Path | Purpose |
| --- | --- |
| `hcp/` | The HCP Terraform organisation and every workspace, this one's included. |
| `azure/` | Microsoft Entra ID app registrations: "Sign in with Microsoft" for Puzzles, and the app Actions signs in as. |
| `mailgun/` | Sending email from `mg.joclegg.dev`. Outputs its DNS records and SMTP login. |
| `supabase/` | The Puzzles Supabase project and its auth settings. `templates/` holds the auth emails. Outputs the public API details. |
| `cloudflare/` | The `joclegg.dev` zone, its DNS, and the Workers. Each Worker's script is in `workers/`. |
| `github/` | Every repository: settings, `main` protection, Pages, submodule webhooks and Actions secrets. |
| `modules/repository/` | The settings every repository shares. |
| `modules/worker/` | A Cloudflare Worker: script, custom domains, cron schedules. |
| `.github/workflows/terraform.yml` | Plans each changed root on pull requests; plans and applies on `main`, weekly, and by hand. Runs roots one at a time, in dependency order. |
| `README.md` | What each root manages, and every secret. |

Outputs flow `azure`, `mailgun` → `supabase`; `mailgun`, `supabase` → `cloudflare` → `github`.

## Conventions

### Checks and applying
- MUST keep `terraform fmt -check -recursive` passing, and `terraform validate` passing in every root (`terraform init -backend=false` first).
- MUST only plan locally. MUST NOT run `terraform apply` by hand: merging to `main` applies.
- MUST read the pull request's plan before asking for a merge, and call out anything destroyed or replaced.
- MUST commit `.terraform.lock.hcl` with Linux and macOS hashes when providers change: `terraform providers lock -platform=linux_amd64 -platform=darwin_arm64`.

### Code
- MUST use snake_case for resource, data, variable, local and output names; MUST name a module's single main resource `this`.
- MUST give every variable a `type`, and a `description` unless its name says it all.
- MUST mark secret variables and outputs `sensitive = true`.
- MUST constrain provider versions in `versions.tf` with `~>`; MUST NOT pin versions inside modules.
- MUST put settings shared by more than one resource in a module under `modules/`, and give each caller only what truly differs.
- MUST make every Cloudflare Worker a `modules/worker` call, with its script in `cloudflare/workers/`.
- MUST explain why, not what, in comments, above the block they describe.

### Roots
- MUST give each new root a `versions.tf`, its workspace in `hcp/hcp.tf`, and its place in the root order in `.github/workflows/terraform.yml`.
- MUST pass values between roots with outputs read through `tfe_outputs`. MUST NOT copy a value another root owns.
- MUST add an output in a pull request before the one that reads it: a plan can't read an output that hasn't been applied.
- MUST NOT make roots read each other's outputs in a cycle.

### Repositories
- MUST add every repository to `github/repositories.tf`, and list its submodules under `submodules`.
- MUST require each repository's CI checks on `main` through `required_checks`.
- MUST NOT remove `prevent_destroy` from a repository or the HCP resources.

### Secrets
- MUST store each secret once, as an Actions secret here, and pass it only to the root that uses it.
- MUST add each new secret to `README.md`.
- MUST NOT commit secret values.

### State
- MUST use `moved` blocks when renaming or moving a resource, so it isn't destroyed and recreated.
- MUST use `import` blocks for anything made by hand.
