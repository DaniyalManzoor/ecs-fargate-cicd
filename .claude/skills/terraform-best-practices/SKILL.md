---
name: terraform-best-practices
description: Terraform best practices drawn from the Google Cloud, HashiCorp and AWS guides and terraform-best-practices.com. Use this skill whenever you write, edit, review, refactor or plan Terraform in this repository, even for a small change. That includes any `.tf` or `.tfvars` file, a new module, stack or environment, backend or state work, provider or module version changes, IAM or secrets in Terraform, importing or moving resources, and questions such as "is this Terraform good?" or "how should I structure this?". Use it before running `terraform apply` or `terraform destroy` too.
---

# Terraform best practices

This skill holds the rules that the main public Terraform guides agree on, and
says which choice this repository makes where they disagree. Following them
keeps the code predictable for the next person and keeps a mistake from
turning into an outage or a bill.

## How to use this skill

1. **Read the project's own rules first.** `.claude/CLAUDE.md` and
   `infra/terraform/README.md` describe the layout and conventions of this
   repository. Where they differ from a rule here, the project's choice wins,
   because consistency inside one codebase matters more than any single guide.
2. **Read the reference file for the work at hand.** Do not load all of them.

   | You are about to | Read |
   | --- | --- |
   | Write or review any `.tf` code | `references/style-and-naming.md` |
   | Add a module, stack or environment, or move code between them | `references/structure-and-modules.md` |
   | Touch a backend, state, imports, or renames | `references/state-and-backend.md` |
   | Handle credentials, IAM, secrets or tags | `references/security.md` |
   | Change a Terraform, provider or module version | `references/versions.md` |
   | Plan, apply, destroy, test, or set up checks and CI | `references/workflow-and-testing.md` |
   | Explain where a rule comes from | `references/sources.md` |

3. **Run the checks before you call the work done.** See "Before you finish".

## The rules that matter most

These are the ones that prevent real damage. The reference files explain each.

**Safety**

- Read every plan before applying it. Stop and ask when it destroys or
  replaces something you did not intend to change. A replaced VPC, database
  or state bucket is not recoverable by re-running Terraform.
- Never edit a state file by hand. Use `moved`, `import` and `removed` blocks
  in code, so the change is reviewed and repeatable.
- Guard the account. Every `provider "aws"` block sets `allowed_account_ids`,
  so a wrong profile fails instead of applying to the wrong account.
- Protect stateful resources such as databases and state buckets with
  `lifecycle { prevent_destroy = true }`.

**Secrets**

- Never commit a secret, an account ID, state, or a `.tfvars` file that holds
  private values. This repository is public.
- A value marked `sensitive` is still stored in plain text in state. Keep
  secrets in a secrets manager, and prefer ephemeral resources and write-only
  arguments so they never reach state.

**Structure**

- Reusable code goes in `modules/`. Root modules (stacks) only call modules
  and configure providers and the backend.
- One state per component per environment. Small states limit the damage of a
  mistake and keep plans fast.
- Environments are directories with identical code and different values. Do
  not use CLI workspaces to separate environments.
- Modules never configure providers or backends.

**Code**

- Names use underscores, are singular, and do not repeat the resource type.
- Every variable has a description and a type. Every output has a description.
- Expose a variable only when a caller has a real reason to change it.
- Prefer references between resources over `depends_on`.
- Use `for_each` for collections and `count` only for on-or-off creation.

**Versions**

- Pin Terraform, providers and modules, and commit `.terraform.lock.hcl` in
  every root module.

## Where the guides disagree, and what this repository does

| Topic | The guides | This repository |
| --- | --- | --- |
| Name of a lone resource | Google says `main`; terraform-best-practices says `this`; AWS allows both | Either, but one choice per module |
| Order inside a variable | HashiCorp: `type`, `description`, `default`. terraform-best-practices: `description`, `type`, `default` | `description`, `type`, `default`, `sensitive`, `validation` |
| Versions file name | HashiCorp: `terraform.tf`. Google and AWS: `versions.tf` | `versions.tf` |
| Public module version | Google: major (`~> 20.0`). HashiCorp: major and minor. AWS: exact | Exact, for example `6.8.0` |
| Environment values | Google: `terraform.tfvars`. AWS: `envs/<env>/terraform.tfvars` | `<env>.auto.tfvars` (committed) plus `terraform.tfvars` (ignored by git, private values) |
| Separating environments | Google: a branch per environment. HashiCorp: `main` is the truth, one directory per environment | One directory per environment |
| Reading another stack | Google: `terraform_remote_state`. HashiCorp: data sources where possible, since state holds sensitive data | `terraform_remote_state` between stacks of the same environment |
| AWS profile | AWS: choose it at run time, do not set `profile` in shared provider blocks | Set in `backend.tf` and `<env>.auto.tfvars`, by the owner's choice. The `aws_profile` variable can be set to null for a pipeline |

All guides agree on never passing `-var` or `-var-file` for routine runs.

## Before you finish

Run the bundled check script from the repository root:

```bash
.claude/skills/terraform-best-practices/scripts/check.sh
```

It runs `terraform fmt -check`, then `terraform validate` in every initialised
root module, then `tflint` and `trivy config` when they are installed. Fix what
it reports. It does not contact AWS.

Then, for any stack you changed:

1. Run `terraform plan` in the stack and read the whole plan.
2. Confirm the counts match your intent: additions, changes and destructions.
3. Apply only when the user asked for it. Report what the plan showed and what
   the apply did.

## Reviewing Terraform

When asked to review, group findings by how much harm they can do:

1. **Can destroy or expose something:** secrets in code or state, missing
   account guard, unpinned versions, public access, a plan that replaces a
   stateful resource.
2. **Will cause trouble later:** resources in root modules, one large state,
   workspaces for environments, `depends_on` where a reference would do,
   variables with no type or description.
3. **Style:** naming, ordering, formatting.

Say which guide a finding comes from when the user may want to check it.
`references/sources.md` lists them.
