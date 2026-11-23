# Versions

Pinning keeps a run next month from behaving differently from a run today.
Sources: AWS Prescriptive Guidance (version management), HashiCorp style
guide, Google Cloud root and reusable module guides.

## What to pin, and how

| Thing | In a root module | In a reusable module |
| --- | --- | --- |
| Terraform | `required_version = ">= 1.10"` or tighter | A lower bound, `>= 1.10` |
| Provider | Pessimistic, `~> 6.28`. Allows 6.x, not 7.0 | A lower bound, `>= 6.28` |
| Registry module | Exact, `6.8.0` | Exact |
| Git module | `?ref=` set to a full commit SHA, with the release in a comment | The same |

- `~> 6.28` allows any 6.x from 6.28 up. `~> 6.28.0` allows patch releases
  only.
- A reusable module states the minimum it needs and assumes newer versions
  work. The root module sets the upper bound, so two modules never conflict.
- Local modules, called by a relative path, take no `version`.
- Put the `terraform` block in `versions.tf`.

## The lock file

- Commit `.terraform.lock.hcl` in every root module. It pins exact provider
  versions and their checksums. Reusable modules do not need one.
- The lock file records checksums only for the platforms where `init` ran. A
  pipeline on Linux needs them too:

  ```bash
  terraform providers lock -platform=linux_amd64 -platform=linux_arm64 -platform=darwin_arm64
  ```

- In a pipeline run `terraform init -lockfile=readonly`, so the job fails
  instead of changing the lock file.

## Upgrading

- To take newer versions inside the constraints, run `terraform init
  -upgrade`, read the change to the lock file, and commit it.
- Upgrade in non-production first, then production.
- For a major provider upgrade:
  1. Move to the latest release of the current major version.
  2. Run `terraform plan` and fix every deprecation warning.
  3. Change the constraint, for example `~> 5.0` to `~> 6.0`, and run
     `terraform init -upgrade`.
  4. Run `terraform plan` again and resolve the differences.
  5. Apply to non-production, then production.
- Read the release notes of a module before raising its version. A module
  upgrade can replace resources.
- Review pins regularly. Dependabot or Renovate can open the pull requests.
  Before merging one, check that the lock file still has checksums for every
  platform in use.

## Checks

- `tflint` has the rules `terraform_required_version` and
  `terraform_required_providers`. Turn them on, and fail the build when a
  version is not pinned.
