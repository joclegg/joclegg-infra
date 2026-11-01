terraform {
  required_providers {
    github = {
      source = "integrations/github"
    }
  }
}

variable "name" {
  type = string
}

variable "description" {
  type    = string
  default = null
}

variable "homepage_url" {
  type    = string
  default = null
}

variable "required_checks" {
  description = "Checks main needs to pass before merging. Every repository protects main either way."
  type        = list(string)
  default     = []
}

variable "pages" {
  description = "GitHub Pages: build_type is workflow (built by Actions) or legacy (served from branch and path)."
  type = object({
    build_type = string
    branch     = optional(string, "main")
    path       = optional(string, "/")
  })
  default = null
}

# The base: every repository gets these settings. Only the variables above differ.
resource "github_repository" "this" {
  name         = var.name
  description  = var.description
  homepage_url = var.homepage_url
  visibility   = "public"

  has_issues   = true
  has_wiki     = true
  has_projects = true

  allow_merge_commit     = true
  allow_squash_merge     = true
  allow_rebase_merge     = true
  delete_branch_on_merge = true

  # Deleting this resource archives the repository instead of deleting it.
  archive_on_destroy = true

  security_and_analysis {
    secret_scanning {
      status = "enabled"
    }
    secret_scanning_push_protection {
      status = "enabled"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_repository_pages" "this" {
  count = var.pages == null ? 0 : 1

  repository = github_repository.this.name
  build_type = var.pages.build_type

  # Only legacy Pages serve from a branch; workflow Pages come from Actions.
  dynamic "source" {
    for_each = var.pages.build_type == "legacy" ? [var.pages] : []

    content {
      branch = source.value.branch
      path   = source.value.path
    }
  }
}

# Part of the base: every repository's main only changes through a pull request.
resource "github_branch_protection" "main" {
  repository_id = github_repository.this.node_id
  pattern       = "main"

  required_status_checks {
    contexts = var.required_checks
  }

  required_pull_request_reviews {
    required_approving_review_count = 0
  }
}

# Branch protection used to be optional, so the protected repositories have it at [0].
moved {
  from = github_branch_protection.main[0]
  to   = github_branch_protection.main
}

output "name" {
  value = github_repository.this.name
}
