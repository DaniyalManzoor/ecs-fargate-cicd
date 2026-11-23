# Workflow and testing

How changes move from an idea to running infrastructure. Sources: Google Cloud
operations, version control and testing guides, HashiCorp style guide, AWS
Prescriptive Guidance, terraform-best-practices.com.

## Version control

- Keep all infrastructure code in version control. `main` is the approved
  state and should be a protected branch.
- Work on a short-lived branch, open a pull request, get a review, merge, and
  delete the branch.
- Never commit secrets. See `security.md`.

## Plan, then apply

1. Run `terraform plan` and read all of it: what is added, changed and
   destroyed.
2. Look for `must be replaced`. A replacement destroys the resource first.
   For a VPC, a subnet, a database or a load balancer that means downtime or
   data loss.
3. For a change that matters, save the plan with `-out` and apply that file,
   so what was reviewed is what runs. Do not commit the plan file.
4. Apply only after the owner approves.
5. After applying, run `terraform plan` again. It should report no changes.

- A person working locally follows the same steps as a pipeline.
- When a plan shows a change you did not make, find out why before applying.
  It is often drift, or a provider or module upgrade.

## Run Terraform from a pipeline

- Automated runs give a consistent environment and a record of who changed
  what.
- The pipeline gets short-lived credentials through OIDC, not stored keys.
- On a pull request: run the checks and `terraform plan`, and show the plan
  to the reviewer.
- On merge: apply, behind an approval for production.
- In a repository with several stacks, run only the stacks whose directories
  changed.
- Limit direct access to production state. Changes go through the pipeline.

## Checks, cheapest first

| Check | Command | Catches |
| --- | --- | --- |
| Format | `terraform fmt -check -recursive` | Inconsistent layout |
| Validate | `terraform validate` | Syntax and type errors. Does not check provider values or state. |
| Lint | `tflint` | Invalid instance types, unused declarations, unpinned versions |
| Security scan | `trivy config .` or `checkov -d .` | Public access, missing encryption, open security groups |
| Docs | `terraform-docs` | README tables out of date |
| Plan | `terraform plan` | What will really change |

- Run format and validate before every commit. Pre-commit hooks from
  `antonbabenko/pre-commit-terraform` automate this.
- Run all of them in the pipeline, and fail the build on errors.
- `scripts/check.sh` in this skill runs the first four where the tools are
  installed.

## Testing

- Test in order of cost: static analysis, then a single module, then the
  whole system. Fail fast.
- Break the architecture into modules so each can be tested alone.
- Terraform's built-in tests live in `tests/*.tftest.hcl` and run with
  `terraform test`. Use them for module logic and validation rules.
- Use variable `validation`, `precondition`, `postcondition` and `check`
  blocks to state what must be true of inputs and of deployed resources.
- Integration tests create real resources. Run them in an account or project
  separate from development and production, give each test its own state and
  unique names, and always destroy afterwards.
- Never point a cleanup tool at production.

## Operating

- Do not change Terraform-managed resources in the console. The next apply
  will undo the change or fail.
- Check for drift on a schedule with `terraform plan -detailed-exitcode`.
- Resources billed by the hour, such as NAT gateways and load balancers, keep
  costing money while idle. Destroy what a lab or test no longer needs.
- Run `terraform destroy` stack by stack, in the reverse of the order they
  were created, and read each plan.
