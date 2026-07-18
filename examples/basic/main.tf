terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "baseline" {
  source = "../.."

  project_id   = var.project_id
  region       = var.region
  network_name = "example-baseline-vpc"

  labels = {
    environment = "sandbox"
  }
}

variable "project_id" {
  description = "Project ID the example baseline is applied to."
  type        = string
}

variable "region" {
  description = "Region for the google provider and baseline resources."
  type        = string
  default     = "us-central1"
}

output "state_bucket_url" {
  value = module.baseline.state_bucket_url
}
