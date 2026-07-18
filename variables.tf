variable "project_id" {
  description = "ID of the project the baseline is applied to."
  type        = string
}

variable "region" {
  description = "Region for the state/log bucket and regional resources."
  type        = string
  default     = "us-central1"
}

variable "activate_apis" {
  description = "APIs to enable as part of the baseline."
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "storage.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]
}

variable "network_name" {
  description = "Name of the baseline VPC network."
  type        = string
  default     = "baseline-vpc"
}

variable "state_bucket_name" {
  description = "Name of the Cloud Storage bucket for Terraform state and logs. Defaults to <project_id>-baseline-state."
  type        = string
  default     = null
}

variable "labels" {
  description = "Labels applied to the baseline resources."
  type        = map(string)
  default     = {}
}
