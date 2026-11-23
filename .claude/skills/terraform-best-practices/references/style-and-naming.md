# Style and naming

Rules for the text of `.tf` files. Sources: HashiCorp style guide, Google
Cloud general style, terraform-best-practices.com, AWS Prescriptive Guidance.

## Contents

- Formatting
- Files
- Naming
- Order inside a block
- Variables
- Outputs
- Locals and expressions
- count and for_each
- Dependencies
- Data sources, scripts and static files

## Formatting

- Run `terraform fmt -recursive`. Its style is not configurable, and every
  guide requires it.
- Indent with two spaces. Align the `=` signs of consecutive one-line
  arguments. `terraform fmt` does both.
- Use `#` for comments. `//` and `/* */` are valid but not idiomatic.
- Separate top-level blocks with one blank line.
- A comment explains why, not what. Add one wherever `count`, `for_each`,
  `depends_on` or `lifecycle` has an effect that is not obvious.

## Files

| File | Holds |
| --- | --- |
| `main.tf` | Resources and module calls. The entry point of every module. |
| `variables.tf` | All variable blocks. |
| `outputs.tf` | All output blocks. |
| `versions.tf` | The `terraform` block: `required_version` and `required_providers`. |
| `providers.tf` | Provider blocks. Root modules only. |
| `backend.tf` | Backend configuration. Root modules only. |
| `locals.tf` | Locals used by several files. Locals used by one file go at its top. |
| `data.tf` | Data sources, only when there are many. Otherwise keep each next to the resource that uses it. |

- Keep resources in `main.tf` until it is hard to review. Then split by
  purpose, for example `network.tf`, `iam.tf`, `loadbalancer.tf`.
- Do not give every resource its own file, and do not create one file per AWS
  service by default.
- A module's root holds only `.tf` files and repository metadata such as
  `README.md`. Extra documentation goes in `docs/`.

## Naming

- Use underscores, not hyphens, in every Terraform identifier: resources, data
  sources, variables, outputs, locals, modules.
- Use hyphens in values that people or AWS see, such as the `Name` tag or a
  DNS name. Cloud naming limits still apply to those values.
- Use lowercase letters and digits.
- Do not repeat the resource type in the name.
  `aws_route_table.public` is right. `aws_route_table.public_route_table` is
  wrong.
- Use singular nouns.
- When a module has one resource of a type, name it `this` or `main`. Pick one
  per module.
- When it has several, use names that tell them apart: `public`, `private`,
  `primary`, `read_replica`.
- Put the unit in the name of a numeric variable, local or output:
  `ram_size_gb`, `timeout_seconds`. Use binary units (MiB, GiB) for storage
  and decimal units for everything else.
- Give booleans a positive name: `enable_flow_logs`, not `disable_flow_logs`.
- Give lists and maps a plural name: `private_subnets`.

## Order inside a block

1. `count` or `for_each`, then a blank line.
2. Plain arguments.
3. Nested blocks.
4. `tags`, as the last real argument.
5. `lifecycle`.
6. `depends_on`.

Separate each group with one blank line. Define a data source before the
resource that reads it, and a resource before the resources that depend on it.

## Variables

- Every variable has a `description` and a `type`.
- Order: `description`, `type`, `default`, `sensitive`, `validation`. (The
  HashiCorp guide puts `type` first. Follow the order the file already uses.)
- Declare a variable only when a caller has a concrete reason to change the
  value. Adding a variable later is safe. Removing one breaks callers.
- A literal used in several places inside a module belongs in a local, not a
  variable.
- Give a default when one value suits every environment, such as a log
  retention period. Give none when the value depends on the environment, such
  as an address range or an account ID, so the caller must supply it.
- Use an empty string or list as a default only when the API accepts an empty
  value.
- A default must be a literal.
- Set `nullable = false` on a variable that must never be null.
- Prefer simple types (`string`, `number`, `bool`, `list(...)`, `map(...)`).
  Use `object(...)` when each key needs its own constraint.
- Set `sensitive = true` on passwords and keys. This hides the value in CLI
  output only. See `security.md`.
- Use `validation` for rules the type cannot express. From Terraform 1.9 a
  validation can refer to other variables.
- Where a variable mirrors a provider argument, reuse the provider's name and
  description for it.

## Outputs

- Every output has a `description`.
- Build an output from a resource attribute, not from an input variable.
  Terraform then orders dependencies correctly.
- For every resource a reusable module creates, give at least one output that
  refers to it.
- Root modules output what other stacks need, especially IDs and endpoints.
- terraform-best-practices.com names outputs `{name}_{type}_{attribute}`, for
  example `private_subnet_ids`. Drop `this` from the name. Use a plural for a
  list.
- Mark an output `sensitive` when it carries a secret.
- Prefer `try(...)` over `element(concat(...))` for values that may not exist.

## Locals and expressions

- Use locals to name an expression that is used more than once, or to split a
  long expression into readable parts.
- Do not add a local for a value used once that is already clear.
- Never put more than one conditional (`a ? b : c`) on a line.
- Move long heredocs to a file and load it with `file()`. Templates use the
  `.tftpl` extension and live in `templates/`.

## count and for_each

- Use `for_each` to create several copies from a map or set. Each copy gets a
  stable key, so removing one item does not shift the others.
- Use `count` for on-or-off creation: `count = var.enable_x ? 1 : 0`. Drive it
  with a boolean variable, not `length(...) > 0`.
- Do not drive `count` or `for_each` with a value that is unknown until apply,
  such as the ID of a resource created in the same run. Terraform cannot plan
  it.
- Use both sparingly. A reader must be able to see what gets created.

## Dependencies

- Prefer implicit dependencies, which come from one resource referring to
  another.
- Refer to an attribute known only after creation, such as `.id`, not to an
  input such as `.name`. Only the first creates a real ordering.
- Use `depends_on` only when the dependency is hidden and cannot be expressed
  by a reference. Add a comment that says why.

## Data sources, scripts and static files

- Put a data source next to the resource that uses it.
- Do not use a data source to look up a resource that another Terraform
  configuration manages when you can read that configuration's outputs.
- Avoid scripts and provisioners. Terraform does not track what a script
  creates. When one is unavoidable, document the reason.
- Scripts that Terraform calls go in `scripts/`. Scripts people run by hand go
  in `helpers/`, documented in the README. Static files go in `files/`.
