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

variable "delete_branch_on_merge" {
  type    = bool
  default = false
}

variable "secret_scanning" {
  description = "Secret scanning and push protection."
  type        = bool
  default     = true
}

variable "required_checks" {
  description = "Checks main needs before merging, through a pull request. null leaves main unprotected."
  type        = list(string)
  default     = null
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
  delete_branch_on_merge = var.delete_branch_on_merge

  # Deleting this resource archives the repository instead of deleting it.
  archive_on_destroy = true

  security_and_analysis {
    secret_scanning {
      status = var.secret_scanning ? "enabled" : "disabled"
    }
    secret_scanning_push_protection {
      status = var.secret_scanning ? "enabled" : "disabled"
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

resource "github_branch_protection" "main" {
  count = var.required_checks == null ? 0 : 1

  repository_id = github_repository.this.node_id
  pattern       = "main"

  required_status_checks {
    contexts = var.required_checks
  }

  required_pull_request_reviews {
    required_approving_review_count = 0
  }
}

output "name" {
  value = github_repository.this.name
}
