# Regression tests for the baseline's *defaults* — a baseline module is its
# defaults, so these are the behaviours worth pinning.
#
# NOTE: `mock_provider` requires Terraform >= 1.7. That is a requirement of this
# test file only and is deliberately NOT reflected in versions.tf, which stays at
# >= 1.5 so consumers on 1.5/1.6 are not broken. Run with `terraform test`.

mock_provider "google" {}

variables {
  project_id = "example-project"
}

run "state_bucket_is_not_publicly_exposable" {
  assert {
    condition     = google_storage_bucket.state.public_access_prevention == "enforced"
    error_message = "The Terraform state bucket must set public_access_prevention = \"enforced\". Left unset it is \"inherited\", and the bucket can be granted to allUsers via IAM."
  }

  assert {
    condition     = google_storage_bucket.state.uniform_bucket_level_access
    error_message = "The state bucket must use uniform bucket-level access so object ACLs cannot re-open it."
  }

  # null == left unset, which the provider treats as false. Either is fine; true
  # is not.
  assert {
    condition     = google_storage_bucket.state.force_destroy != true
    error_message = "The state bucket must not enable force_destroy; a stray destroy would take the state history with it."
  }

  assert {
    condition     = google_storage_bucket.state.versioning[0].enabled
    error_message = "The state bucket must be versioned so a corrupted state file can be rolled back."
  }
}

run "state_bucket_name_defaults_to_the_project_prefix" {
  assert {
    condition     = google_storage_bucket.state.name == "example-project-baseline-state"
    error_message = "state_bucket_name must default to <project_id>-baseline-state."
  }

  assert {
    condition     = google_storage_bucket.state.location == "us-central1"
    error_message = "The state bucket must be created in var.region."
  }
}

run "audit_config_covers_data_access_by_default" {
  assert {
    condition     = length(google_project_iam_audit_config.this) == 1
    error_message = "The baseline must configure project audit logging by default."
  }

  assert {
    condition     = google_project_iam_audit_config.this[0].service == "allServices"
    error_message = "Audit logging must apply to allServices, not a single service."
  }

  # The bug this guards: an audit config carrying only ADMIN_READ records who
  # changed configuration and nothing about who read or wrote data.
  assert {
    condition = length(setsubtract(
      toset(["ADMIN_READ", "DATA_READ", "DATA_WRITE"]),
      toset([for c in google_project_iam_audit_config.this[0].audit_log_config : c.log_type])
    )) == 0
    error_message = "Audit config must include ADMIN_READ, DATA_READ and DATA_WRITE. Omitting the DATA_* types records admin activity only."
  }

  assert {
    condition     = contains(output.audit_log_types, "DATA_WRITE")
    error_message = "The audit_log_types output must report the DATA_* types that were actually configured."
  }
}

run "audit_config_is_opt_out_as_a_whole" {
  variables {
    enable_data_access_audit_logs = false
  }

  assert {
    condition     = length(google_project_iam_audit_config.this) == 0
    error_message = "Setting enable_data_access_audit_logs = false must remove the audit config entirely."
  }

  assert {
    condition     = output.audit_logged_service == null
    error_message = "audit_logged_service must be null when audit logging is disabled."
  }
}

run "baseline_cannot_be_instantiated_as_a_no_op" {
  # Called with nothing but project_id, the module must still enable the core
  # APIs, create the state bucket, create the VPC and configure audit logging.
  # A baseline that applies cleanly and establishes nothing is the failure mode.
  assert {
    condition     = length(google_project_service.this) >= 5
    error_message = "The default activate_apis list must enable the core APIs."
  }

  assert {
    condition     = contains(var.activate_apis, "cloudresourcemanager.googleapis.com")
    error_message = "cloudresourcemanager.googleapis.com must be enabled by default; google_project_iam_audit_config needs it on a fresh project."
  }

  assert {
    condition     = length(google_project_iam_audit_config.this) == 1
    error_message = "Audit logging must be on by default."
  }

  assert {
    condition     = google_compute_network.this.auto_create_subnetworks == false
    error_message = "The baseline VPC must be custom-mode; auto-mode creates a subnet with a predictable range in every region."
  }
}

run "default_service_accounts_are_left_alone_by_default" {
  # Deprivileging, disabling or deleting the default service accounts breaks
  # workloads still running as them, so upgrading the module must not do it.
  assert {
    condition     = length(google_project_default_service_accounts.this) == 0
    error_message = "default_service_account must default to \"keep\" and create no google_project_default_service_accounts resource."
  }

  assert {
    condition     = output.default_service_account_action == null
    error_message = "default_service_account_action must be null when default_service_account is \"keep\"."
  }
}

run "default_service_accounts_can_be_deprivileged" {
  variables {
    default_service_account = "deprivilege"
  }

  assert {
    condition     = length(google_project_default_service_accounts.this) == 1
    error_message = "default_service_account = \"deprivilege\" must create one google_project_default_service_accounts resource."
  }

  assert {
    condition     = google_project_default_service_accounts.this[0].action == "DEPRIVILEGE"
    error_message = "The action must be the upper-case enum the provider expects."
  }

  assert {
    condition     = google_project_default_service_accounts.this[0].project == "example-project"
    error_message = "The action must target var.project_id."
  }

  assert {
    condition     = output.default_service_account_action == "DEPRIVILEGE"
    error_message = "default_service_account_action must report the applied action."
  }
}

run "default_service_accounts_can_be_disabled" {
  variables {
    default_service_account = "disable"
  }

  assert {
    condition     = google_project_default_service_accounts.this[0].action == "DISABLE"
    error_message = "default_service_account = \"disable\" must map to DISABLE."
  }

  assert {
    condition     = google_project_default_service_accounts.this[0].restore_policy == "REVERT_AND_IGNORE_FAILURE"
    error_message = "Destroying the resource must try to re-enable the accounts without failing the destroy."
  }
}

run "default_service_accounts_can_be_deleted" {
  variables {
    default_service_account = "delete"
  }

  assert {
    condition     = google_project_default_service_accounts.this[0].action == "DELETE"
    error_message = "default_service_account = \"delete\" must map to DELETE."
  }
}

run "rejects_unknown_default_service_account_action" {
  command = plan

  variables {
    default_service_account = "DEPRIVILEGE"
  }

  expect_failures = [var.default_service_account]
}
