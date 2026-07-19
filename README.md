# terraform-google-baseline

Terraform landing-zone module for [Google Cloud](https://cloud.google.com/)
that establishes a minimal project baseline: it enables a set of core APIs
(`google_project_service`), creates a versioned Cloud Storage bucket for
Terraform state and logs (`google_storage_bucket`), and provisions a
custom-mode VPC network (`google_compute_network`).

## Usage

```hcl
module "baseline" {
  source = "github.com/moveeeax/terraform-google-baseline"

  project_id   = var.project_id
  region       = "us-central1"
  network_name = "prod-vpc"

  activate_apis = [
    "compute.googleapis.com",
    "run.googleapis.com",
    "logging.googleapis.com",
  ]
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| google    | >= 5.0   |

## Inputs

| Name                | Description                                              | Type           | Default          | Required |
|---------------------|----------------------------------------------------------|----------------|------------------|:--------:|
| `project_id`        | ID of the project the baseline is applied to.            | `string`       | n/a              |   yes    |
| `region`            | Region for the state bucket and regional resources.      | `string`       | `"us-central1"`  |    no    |
| `activate_apis`     | APIs to enable as part of the baseline.                  | `list(string)` | core APIs        |    no    |
| `network_name`      | Name of the baseline VPC network.                        | `string`       | `"baseline-vpc"` |    no    |
| `state_bucket_name` | Name of the state and logs bucket.                       | `string`       | `null`           |    no    |
| `labels`            | Labels applied to the baseline resources.                | `map(string)`  | `{}`             |    no    |

## Outputs

| Name                | Description                                       |
|---------------------|---------------------------------------------------|
| `enabled_apis`      | APIs enabled by the baseline.                    |
| `state_bucket_name` | Name of the Terraform state and logs bucket.     |
| `state_bucket_url`  | Base gs:// URL of the state and logs bucket.     |
| `network_id`        | Identifier of the baseline VPC network.          |
| `network_self_link` | URI of the baseline VPC network.                 |

## License

[MIT](LICENSE)
