output "enabled_apis" {
  description = "APIs enabled by the baseline."
  value       = [for s in google_project_service.this : s.service]
}

output "state_bucket_name" {
  description = "Name of the Terraform state and logs bucket."
  value       = google_storage_bucket.state.name
}

output "state_bucket_url" {
  description = "Base gs:// URL of the state and logs bucket."
  value       = google_storage_bucket.state.url
}

output "network_id" {
  description = "Identifier of the baseline VPC network."
  value       = google_compute_network.this.id
}

output "network_self_link" {
  description = "URI of the baseline VPC network."
  value       = google_compute_network.this.self_link
}
