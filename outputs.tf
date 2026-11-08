output "enabled_apis" {
  description = "APIs enabled by the baseline."
  value       = [for s in google_project_service.this : s.service]
}

output "state_bucket_name" {
  description = "Name of the Terraform state bucket."
  value       = google_storage_bucket.state.name
}

output "state_bucket_url" {
  description = "Base gs:// URL of the Terraform state bucket."
  value       = google_storage_bucket.state.url
}

output "audit_logged_service" {
  description = "Service the project audit config applies to, or null when data access audit logging is disabled."
  value       = one(google_project_iam_audit_config.this[*].service)
}

output "audit_log_types" {
  description = "Audit log types configured on the project, or an empty list when data access audit logging is disabled."
  value       = var.enable_data_access_audit_logs ? local.audit_log_types : []
}

output "network_id" {
  description = "Identifier of the baseline VPC network."
  value       = google_compute_network.this.id
}

output "network_self_link" {
  description = "URI of the baseline VPC network."
  value       = google_compute_network.this.self_link
}

output "default_service_account_action" {
  description = "Action applied to the default service accounts (DEPRIVILEGE, DISABLE or DELETE), or null when default_service_account is \"keep\"."
  value       = one(google_project_default_service_accounts.this[*].action)
}
