locals {
  state_bucket_name = coalesce(var.state_bucket_name, "${var.project_id}-baseline-state")
}

resource "google_project_service" "this" {
  for_each = toset(var.activate_apis)

  project = var.project_id
  service = each.value

  disable_on_destroy = false
}

resource "google_storage_bucket" "state" {
  project                     = var.project_id
  name                        = local.state_bucket_name
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  labels                      = var.labels

  versioning {
    enabled = true
  }

  depends_on = [google_project_service.this]
}

resource "google_compute_network" "this" {
  project                 = var.project_id
  name                    = var.network_name
  auto_create_subnetworks = false

  depends_on = [google_project_service.this]
}
