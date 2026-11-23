# Structure and modules

How to lay out a repository, a root module and a reusable module. Sources:
Google Cloud root and reusable module guides, HashiCorp standard module
structure and style guide, terraform-best-practices.com, AWS Prescriptive
Guidance.

## Two kinds of module

- A **root module** (called a stack in this repository) is a directory where
  you run `terraform plan` and `terraform apply`. It configures the backend
  and the providers, and calls modules.
- A **reusable module** defines resources. It is called by root modules and
  never run on its own.

Keep them apart: reusable modules in `modules/<name>`, root modules in
`envs/<environment>/<stack>`.

## Repository layout

```
infra/terraform/
├── bootstrap/                 creates the state bucket
├── modules/
│   └── <name>/                reusable code
└── envs/
    └── <environment>/
        └── <stack>/           one root module, one state
```

- Put each environment in its own directory. Each has its own backend
  configuration, and so its own state.
- Do not separate environments with CLI workspaces. A workspace is easy to
  forget, shares one backend, and hides which environment the code targets.
  Use only the default workspace.
- The `.tf` files of a stack are the same in every environment. Only the
  values differ.
- Store infrastructure configuration apart from application code, and group
  it by logically related resources.

## Size of a state

- Keep a state small. Google's limit is 100 resources, and ideally a few
  dozen. Every plan and apply calls the API for each resource, and one bad
  change can touch everything in the state.
- Split by component, for example `vpc`, `backend`, `database`. Put unrelated
  resources in different states to limit the damage of a mistake.
- Separate parts that need different approval or different permissions.

## Root modules

- Contain a `backend.tf`, a `main.tf` that calls modules, `providers.tf` and
  `versions.tf`.
- Do not define resources in a root module when a module can hold them.
- Declare every provider in the root module and pin it. See `versions.md`.
- Set a default `region` and `allowed_account_ids` on each AWS provider.
- Supply values through tfvars files that load automatically. Do not use
  `-var` or `-var-file` for routine runs.
- Commit `.terraform.lock.hcl`.
- Output what other stacks need, especially IDs and endpoints.

## Reusable modules

- Follow the standard structure: `main.tf`, `variables.tf` and `outputs.tf`,
  plus `versions.tf`, even when a file would be short.
- Give each module one capability, named after something the architecture
  talks about: a network, a data tier, an application service.
- Do not wrap a single resource. If the best name for the module is the
  resource type, use the resource directly.
- Do not configure providers or backends in a module. A module with its own
  provider cannot be removed cleanly and cannot be reused across accounts or
  Regions.
- Declare `required_providers` with a minimum version, for example `>= 6.28`.
  The root module holds the upper bound.
- Hard-code what is the same everywhere. Expose only what differs between
  callers.
- For every resource the module creates, give at least one output that
  refers to it.
- Offer a `tags` variable (a map, default `{}`) for tags beyond the provider's
  defaults.
- Keep nesting to one or two levels. The root module wires modules together.
  Modules should not call each other several levels deep.
- Nested modules go in `modules/<name>` inside the parent and are private
  unless the parent's documentation says otherwise.
- Write a `README.md` for each module: its purpose, what it creates, and what
  the caller must provide. Generate the inputs and outputs tables with
  `terraform-docs` instead of writing them by hand.
- Put working examples in `examples/<name>/`.
- When moving resources into or between modules, add `moved` blocks so
  Terraform renames them in state instead of recreating them.
- Shared modules use semantic versioning and name their owners in a
  `CODEOWNERS` file.

## Community modules

- Prefer a well-maintained community module, such as those in
  `terraform-aws-modules`, over hand-written resources for common building
  blocks.
- Call it in the plain style of its registry example. Pin an exact version and
  change it on purpose, after reading the release notes.
- Read the inputs that change cost or scale before using it. For example the
  VPC module creates one NAT gateway per zone unless `single_nat_gateway` is
  true.

## Sharing values between stacks

- A stack reads another stack's outputs with a `terraform_remote_state` data
  source that points at the other stack's state key.
- State can hold sensitive values, so anyone who can read a state can read
  them. When a consumer should not see the whole state, look the resource up
  with a provider data source instead, by ID or by tag.
- Do not copy an ID from one stack into another by hand. It goes stale.
- Tag resources that other stacks need to find, for example `Tier = private`
  on subnets.

## Prefer separate attachment resources

Managing the same object through both a nested block and a separate resource
makes Terraform report changes forever. AWS recommends the separate resource:

- One `aws_vpc_security_group_ingress_rule` or
  `aws_vpc_security_group_egress_rule` per rule. Do not use `ingress` and
  `egress` blocks, or `aws_security_group_rule`.
- `aws_iam_role_policy_attachment`, not `managed_policy_arns`.
- The `aws_s3_bucket_*` resources (versioning, encryption, lifecycle), not the
  deprecated arguments on `aws_s3_bucket`.
