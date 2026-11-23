# Security

Credentials, permissions, secrets, tags and scanning. Sources: AWS
Prescriptive Guidance (security), Google Cloud security and version control
guides, HashiCorp style guide.

## What never goes in git

- Secrets, passwords, tokens and private keys, in any file.
- State files and their backups.
- `.tfvars` files that hold private values.
- Saved plan files. A plan can contain secrets.
- The `.terraform` directory.

In this repository the AWS account ID is also kept out of git, because the
repository is public.

Always commit: all `.tf` files, `.terraform.lock.hcl`, `.gitignore` and
`README.md`.

## Guard the account

- Set `allowed_account_ids` on every `provider "aws"` block. A run with the
  wrong credentials then fails before it changes anything.
- Use `forbidden_account_ids` when one configuration runs in several accounts
  but must never run in production.
- Before a destructive command, confirm the identity with
  `aws sts get-caller-identity`.

## Credentials

- Use IAM roles, not IAM users, wherever possible.
- Do not keep long-lived access keys on a workstation. Sign in with IAM
  Identity Center (`aws sso login`) or `aws login`.
- Give Terraform a dedicated role with the minimum permissions, and let only
  the identities that run Terraform assume it.
- In a pipeline, use OIDC. For GitHub Actions the role's trust policy must
  restrict `token.actions.githubusercontent.com:sub` to the repository and
  branch or environment.
- Separate the permissions for planning and applying. A plan role reads. An
  apply role writes, and sits behind an approval.
- AWS advises choosing the profile at run time and not setting `profile` in
  shared provider blocks. This repository sets it on purpose, so the owner
  does not have to pass it. Leave a variable that a pipeline can set to null.

## Least privilege

- Grant only the actions Terraform needs, on the specific resources it
  manages. Start from an empty policy and add to it.
- For one state with S3 locking, the role needs: `s3:ListBucket` on the
  bucket, `s3:GetObject` and `s3:PutObject` on the state key, and
  `s3:GetObject`, `s3:PutObject` and `s3:DeleteObject` on the `.tflock` key.
  With KMS, add `kms:Decrypt`, `kms:Encrypt` and `kms:GenerateDataKey`.
- Scope security group egress to the destinations that are needed. Scanners
  rate unrestricted egress as critical.
- Validate IAM policies in the pipeline with
  `aws accessanalyzer validate-policy`.

## Keeping secrets out of state

- Store secrets in AWS Secrets Manager or SSM Parameter Store, not in
  variables or tfvars files.
- `sensitive = true` hides a value in CLI output. The value is still written
  to state in plain text.
- **Service-managed passwords** are best where supported. For RDS, set
  `manage_master_user_password = true` and AWS generates and stores it.
- **Write-only arguments** (Terraform 1.11 and newer) are never stored, for
  example `password_wo` on `aws_db_instance` and `secret_string_wo`. Terraform
  sends the value only when its version argument changes.
- **Ephemeral resources** (Terraform 1.10 and newer) read a value without
  storing it, for example the ephemeral `aws_secretsmanager_secret_version`.
- **Ephemeral variables and outputs** pass a secret between modules without
  storing it.
- Resources such as `tls_private_key` put the private key in state. Avoid
  them, or treat that state as secret.
- Mark outputs that carry secrets as `sensitive`.

## Tags

- Tag every resource that accepts tags. Tags make cost and ownership
  traceable.
- Put shared tags in the provider's `default_tags`, for example `Project`,
  `Environment`, `Stack` and `ManagedBy`. Set only `Name` and resource-specific
  tags on each resource.
- `aws_autoscaling_group` does not receive default tags. Read them with the
  `aws_default_tags` data source and apply them with a `dynamic "tag"` block.
- When writing a policy or check, test `default_tags` on the provider rather
  than `tags_all`, which is not known until apply.

## Protect what holds data

- Add `lifecycle { prevent_destroy = true }` to databases, state buckets and
  other stateful resources.
- Turn on deletion protection where the service offers it.
- Encrypt data at rest, for example `storage_encrypted` on RDS.

## Scanning

- Run a static scanner in the pipeline and before committing:
  `trivy config .` or `checkov -d .`, and `tflint` with the AWS ruleset.
- Fix findings or record why one is accepted. Do not leave them unexplained.
- Detect drift on a schedule with `terraform plan -detailed-exitcode`. Exit
  code 0 means no changes, 1 means the plan failed, 2 means drift or pending
  changes.
- For rules that must hold everywhere, such as required tags or approved
  instance types, use policy as code: Sentinel or Open Policy Agent.
