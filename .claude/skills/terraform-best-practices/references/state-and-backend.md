# State and backend

State is Terraform's only record of what it created. Lose it or corrupt it and
Terraform can no longer update or destroy those resources. Sources: AWS
Prescriptive Guidance (backend, security), Google Cloud security and
operations guides, HashiCorp style guide, terraform-best-practices.com.

## Remote state from the start

- Use a remote backend from the first day. Do not keep state on a laptop or in
  git.
- For AWS workloads, use the S3 backend.
- Add `*.tfstate`, `*.tfstate.*` and `.terraform/` to `.gitignore`.
- The one exception is a bootstrap configuration that creates the state
  bucket. Its own state is local, because the bucket does not exist yet.

## Locking

- Turn on S3 native locking with `use_lockfile = true`. It needs Terraform
  1.10 or newer; AWS recommends requiring 1.11.
- The lock is an object named `<key>.tflock` beside the state file.
- `dynamodb_table` locking is deprecated. Do not add it to new backends.
- When a run fails with `Error acquiring the state lock`, another run holds
  it. Wait, or pass `-lock-timeout=5m`. Use `terraform force-unlock` only
  after confirming no run is in progress.

## The state bucket

- Turn on versioning, so an earlier state can be restored.
- Encrypt it. AES256 is the minimum. AWS recommends SSE-KMS with a
  customer-managed key (`kms_key_id`) and S3 Bucket Keys for production.
- Block all public access. Set Object Ownership to bucket owner enforced.
- Add a bucket policy that denies any request where `aws:SecureTransport` is
  false.
- Protect the bucket from deletion with `prevent_destroy`.
- Limit who can read it. State can contain secrets in plain text. Ideally
  only the pipeline and a few administrators have access.
- For production, record access with CloudTrail data events and back the
  bucket up.

## Keys and separation

- One state per component per environment. This repository uses the key
  `<environment>/<stack>/terraform.tfstate`.
- Use a separate backend for each environment. AWS recommends a separate
  account per environment, with that environment's state bucket inside it.
- Restrict production state to read-only for most people. Changes come from
  the pipeline.
- A backend block cannot read variables. Write its values as literals, or pass
  them with `terraform init -backend-config=...`.

## Changing what state tracks

Use configuration blocks, not `terraform state` commands. A block is reviewed
in a pull request, works the same for everyone, and applies in every
environment.

| Need | Block | Since |
| --- | --- | --- |
| Rename a resource or move it into a module | `moved` | Terraform 1.1 |
| Bring an existing resource under Terraform | `import` | Terraform 1.5 |
| Stop managing a resource without destroying it | `removed` with `destroy = false` | Terraform 1.7 |

- `terraform plan -generate-config-out=<file>` writes the configuration for an
  `import` block.
- Leave a `moved` block in place until every environment has applied it.
- Use `terraform state mv` or `terraform state rm` only when a block cannot
  express the change. Pull a backup first with `terraform state pull`.
- Never edit a state file by hand.
- Google's guide advises against importing at all where you can create the
  resource through Terraform instead. After an import, manage the resource
  only with Terraform.

## Moving a backend or a key

1. Take a backup: `terraform state pull > backup.tfstate`.
2. Change the `backend` block.
3. Run `terraform init -migrate-state`.
4. Run `terraform plan`. It must report no changes.
5. Remove the old state object only after step 4 passes.

## Secrets in state

- Anything Terraform reads or writes can end up in state in plain text,
  including values marked `sensitive`.
- Encrypt state always, even when you believe it holds no secrets.
- Do not try to encrypt values yourself inside Terraform.
- See `security.md` for how to keep secrets out of state.
