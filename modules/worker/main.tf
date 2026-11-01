# A Cloudflare Worker: its script, the hostnames it serves and its cron
# schedules. Every Worker in cloudflare/ is one of these.

terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

variable "account_id" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "name" {
  description = "The script's name on Cloudflare."
  type        = string
}

variable "file" {
  description = "Path to the script. Its file name is also the main module's."
  type        = string
}

variable "bindings" {
  description = "Environment bindings: plain_text or secret_text."
  type = list(object({
    type = string
    name = string
    text = string
  }))
  default = []
}

variable "hostnames" {
  description = "Hostnames on the zone the Worker serves. Each gets its DNS record and certificate."
  type        = set(string)
  default     = []
}

variable "schedules" {
  description = "Cron schedules that run the Worker's scheduled handler."
  type        = list(string)
  default     = []
}

resource "cloudflare_workers_script" "this" {
  account_id         = var.account_id
  script_name        = var.name
  content            = file(var.file)
  main_module        = basename(var.file)
  compatibility_date = "2026-10-01"
  bindings           = length(var.bindings) == 0 ? null : var.bindings
}

resource "cloudflare_workers_custom_domain" "this" {
  for_each = var.hostnames

  account_id = var.account_id
  zone_id    = var.zone_id
  hostname   = each.value
  service    = cloudflare_workers_script.this.script_name
}

resource "cloudflare_workers_cron_trigger" "this" {
  count = length(var.schedules) == 0 ? 0 : 1

  account_id  = var.account_id
  script_name = cloudflare_workers_script.this.script_name
  schedules   = [for cron in var.schedules : { cron = cron }]
}

output "script_name" {
  value = cloudflare_workers_script.this.script_name
}

output "hostnames" {
  value = [for domain in cloudflare_workers_custom_domain.this : domain.hostname]
}
