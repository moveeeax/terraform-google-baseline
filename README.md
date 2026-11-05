# terraform-google-baseline

Terraform landing-zone module for [Google Cloud](https://cloud.google.com/)
that establishes a minimal project baseline: it enables a set of core APIs
(`google_project_service`), creates a versioned, non-public Cloud Storage
bucket for Terraform state (`google_storage_bucket`), configures project-wide
Cloud Audit Logging (`google_project_iam_audit_config`), and provisions a
custom-mode VPC network (`google_compute_network`).

## Baseline defaults

A baseline module is mostly its defaults, so the security-relevant ones are
stated explicitly rather than left to the environment:

| Default | Why |
|---|---|
| `public_access_prevention = "enforced"` on the state bucket | Uniform bucket-level access removes object ACLs but does **not** stop an IAM binding to `allUsers`. Unset, the setting is `"inherited"` — off unless an org policy happens to enforce it. Terraform state routinely contains secrets. |
| `uniform_bucket_level_access = true` | Object ACLs cannot re-open the bucket. |
| Bucket versioning on, `force_destroy` unset | A corrupted state file can be rolled back; a stray destroy does not take the history with it. |
| Audit logging with `ADMIN_READ` + `DATA_READ` + `DATA_WRITE` on `allServices` | Google always writes Admin Activity logs, but Data Access logs are **off by default** for every service except BigQuery. An audit config without the `DATA_*` types records who changed configuration and nothing about who read or wrote data. This is CIS GCP Foundations 2.1. |
| Custom-mode VPC (`auto_create_subnetworks = false`) | Auto-mode creates a subnet with a predictable range in every region. |

The set of audit log types is intentionally **not** configurable: the two types
covering data access are exactly the ones trimmed first when someone is chasing
log volume. Use `enable_data_access_audit_logs = false` to opt out as a whole
if you configure audit logging elsewhere.

## Usage

```hcl
module "baseline" {
  source = "github.com/moveeeax/terraform-google-baseline?ref=v1.0.0"

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

| Name                            | Description                                                                 | Type           | Default          | Required |
|---------------------------------|-----------------------------------------------------------------------------|----------------|------------------|:--------:|
| `project_id`                    | ID of the project the baseline is applied to.                               | `string`       | n/a              |   yes    |
| `region`                        | Region for the state bucket and regional resources.                         | `string`       | `"us-central1"`  |    no    |
| `activate_apis`                 | APIs to enable as part of the baseline.                                     | `list(string)` | core APIs        |    no    |
| `network_name`                  | Name of the baseline VPC network.                                           | `string`       | `"baseline-vpc"` |    no    |
| `state_bucket_name`             | Name of the Terraform state bucket.                                         | `string`       | `null`           |    no    |
| `labels`                        | Labels applied to the baseline resources.                                   | `map(string)`  | `{}`             |    no    |
| `enable_data_access_audit_logs` | Configure `allServices` audit logging with `ADMIN_READ`/`DATA_READ`/`DATA_WRITE`. | `bool`   | `true`           |    no    |

## Outputs

| Name                   | Description                                                        |
|------------------------|--------------------------------------------------------------------|
| `enabled_apis`         | APIs enabled by the baseline.                                      |
| `state_bucket_name`    | Name of the Terraform state bucket.                                |
| `state_bucket_url`     | Base gs:// URL of the Terraform state bucket.                      |
| `network_id`           | Identifier of the baseline VPC network.                            |
| `network_self_link`    | URI of the baseline VPC network.                                   |
| `audit_logged_service` | Service the audit config applies to, or `null` when disabled.      |
| `audit_log_types`      | Audit log types configured, or `[]` when disabled.                 |

## Tests

```
terraform init -backend=false
terraform test
```

The suite in [`tests/`](tests) pins the defaults above using `mock_provider`,
so it needs no cloud credentials and no network. `mock_provider` requires
Terraform >= 1.7; that is a requirement of the tests only, and the module
itself still supports >= 1.5.

## License

[MIT](LICENSE)
