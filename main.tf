locals {
  state_bucket_name = coalesce(var.state_bucket_name, "${var.project_id}-baseline-state")

  # Deliberately not a variable. Making the set configurable is how audit
  # baselines end up recording ADMIN_READ only: the two log types that cover
  # data access are exactly the ones an operator trimming log volume removes
  # first. Use enable_data_access_audit_logs to opt out as a whole instead.
  audit_log_types = ["ADMIN_READ", "DATA_READ", "DATA_WRITE"]
}

resource "google_project_service" "this" {
  for_each = toset(var.activate_apis)

  project = var.project_id
  service = each.value

  disable_on_destroy = false
}

resource "google_storage_bucket" "state" {
  project       = var.project_id
  name          = local.state_bucket_name
  location      = var.region
  storage_class = "STANDARD"
  labels        = var.labels

  # Uniform bucket-level access removes object ACLs, but on its own it does not
  # stop the bucket from being shared with allUsers/allAuthenticatedUsers via an
  # IAM binding. Public access prevention is the control that actually does, and
  # it is "inherited" (i.e. off, unless an org policy happens to set it) when
  # left unset. This bucket holds Terraform state, which routinely contains
  # secrets, so both are pinned on here rather than left to the environment.
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  depends_on = [google_project_service.this]
}

# Google always writes Admin Activity audit logs, but Data Access logs
# (DATA_READ/DATA_WRITE) are off by default for every service except BigQuery.
# A baseline that configures no audit config therefore records *who changed
# configuration* and nothing about who read or wrote data. Enabling all three
# log types for allServices is CIS GCP Foundations 2.1.
resource "google_project_iam_audit_config" "this" {
  count = var.enable_data_access_audit_logs ? 1 : 0

  project = var.project_id
  service = "allServices"

  dynamic "audit_log_config" {
    for_each = toset(local.audit_log_types)

    content {
      log_type = audit_log_config.value
    }
  }

  depends_on = [google_project_service.this]
}

resource "google_compute_network" "this" {
  project                 = var.project_id
  name                    = var.network_name
  auto_create_subnetworks = false

  depends_on = [google_project_service.this]
}
