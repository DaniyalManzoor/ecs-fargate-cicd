# Terraform

Infrastructure for the ECS lab. Reusable code lives in `modules/`; each
environment under `envs/` calls those modules with its own values.

```
infra/terraform/
├── bootstrap/        S3 bucket that stores Terraform state. Run once.
├── modules/
│   └── vpc/          Reusable VPC: subnets, NAT, S3 endpoint, flow logs.
└── envs/
    ├── dev/
    │   └── vpc/      The dev VPC stack.
    └── prod/
        └── vpc/      The prod VPC stack. Same code as dev, different values.
```

## How it is organised

- **One folder per stack.** A stack is one part of an environment, such as
  `vpc` or `backend`. Each stack has its own state file in S3, so a mistake
  in one stack cannot damage another.
- **Environments differ only in values.** The `.tf` files of `envs/dev/vpc`
  and `envs/prod/vpc` are identical. What differs is `<env>.auto.tfvars`
  and the state key in `backend.tf`.
- **No resources in `envs/`.** Stacks only call modules. Resources are
  defined in `modules/`.

## Files in a stack

| File | Purpose |
| --- | --- |
| `main.tf` | Calls the modules. |
| `variables.tf` | Declares the settings the stack accepts. |
| `outputs.tf` | Values that other stacks read. |
| `providers.tf` | AWS provider, account guard and default tags. |
| `versions.tf` | Terraform and provider versions. |
| `backend.tf` | Where the state is stored: `<env>/<stack>/terraform.tfstate`. |
| `<env>.auto.tfvars` | The values for this environment. Loaded automatically. |
| `example.tfvars` | Template for `terraform.tfvars`. |
| `terraform.tfvars` | Your AWS account ID. Ignored by git. |

## Run a stack

```bash
cd envs/dev/vpc
cp example.tfvars terraform.tfvars   # first time only; then set your account ID
terraform init
terraform plan
terraform apply
```

The AWS profile is set in `<env>.auto.tfvars` and `backend.tf`, so no
`AWS_PROFILE` or `-var-file` is needed.

## Dev and prod

| Setting | dev | prod |
| --- | --- | --- |
| Address range | `10.0.0.0/16` | `10.1.0.0/16` |
| Availability Zones | 2 | 3 |
| NAT gateways | 1 shared | 1 per zone |
| Flow logs | off | on, kept 90 days |

Prod is defined but not created. Applying it creates three NAT gateways,
which are billed by the hour. A real production should use a separate AWS
account and profile.

## Add a stack

To add the backend (load balancer, ECS cluster and service):

1. Put the reusable code in `modules/backend/`.
2. Create `envs/dev/backend/` with the same files as `envs/dev/vpc/`.
3. Set the state key in `backend.tf` to `dev/backend/terraform.tfstate`.
4. Read the VPC stack's outputs with a `terraform_remote_state` data source
   that points at `dev/vpc/terraform.tfstate`.
5. Copy the folder to `envs/prod/backend/` and change the values.

## Add an environment

Copy `envs/dev` to `envs/<name>`. In each stack, rename the `.auto.tfvars`
file, change its values, and change the state key in `backend.tf`.
