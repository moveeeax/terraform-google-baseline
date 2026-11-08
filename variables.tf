variable "project_id" {
  description = "ID of the project the baseline is applied to."
  type        = string
}

variable "region" {
  description = "Region for the state bucket and regional resources."
  type        = string
  default     = "us-central1"
}

variable "activate_apis" {
  description = "APIs to enable as part of the baseline."
  type        = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "storage.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]
}

variable "enable_data_access_audit_logs" {
  description = <<-EOT
    Configure Cloud Audit Logging for allServices with ADMIN_READ, DATA_READ and
    DATA_WRITE (CIS GCP Foundations 2.1). Admin Activity logs are written by
    Google regardless, but Data Access logs are off by default, so setting this
    to false leaves the project recording configuration changes only and nothing
    about who read or wrote data. Data Access logs on allServices can be high
    volume; disable it only if you configure audit logging elsewhere.
  EOT
  type        = bool
  default     = true
}

variable "default_service_account" {
  description = <<-EOT
    What to do with the project's default service accounts (Compute Engine and
    App Engine), which are created with roles/editor. One of:
      * "keep"        - leave them alone (default).
      * "deprivilege" - remove roles/editor from them. Not reverted on destroy.
      * "disable"     - disable them. Re-enabled on destroy.
      * "delete"      - delete them. Undeleted on destroy if still possible.
    Anything other than "keep" breaks workloads that still run as a default
    service account; move them to dedicated service accounts first.
    "deprivilege" is the recommended setting.
  EOT
  type        = string
  default     = "keep"

  validation {
    condition     = contains(["keep", "deprivilege", "disable", "delete"], var.default_service_account)
    error_message = "default_service_account must be one of \"keep\", \"deprivilege\", \"disable\" or \"delete\"."
  }
}

variable "network_name" {
  description = "Name of the baseline VPC network."
  type        = string
  default     = "baseline-vpc"
}

variable "state_bucket_name" {
  description = "Name of the Cloud Storage bucket for Terraform state. Defaults to <project_id>-baseline-state."
  type        = string
  default     = null
}

variable "labels" {
  description = "Labels applied to the baseline resources."
  type        = map(string)
  default     = {}
}
