# ecs-fargate-cicd

A lab that ships a TypeScript API to Amazon ECS on Fargate with GitHub
Actions, ECR and OIDC. Progress and the remaining phases are tracked in
`docs/checklist.md`.

## Structure

```
.
├── app/                      Fastify API in TypeScript, tests, Dockerfile
├── .github/workflows/
│   └── deploy.yml            Test, build and push the image, deploy
├── infra/terraform/
│   ├── README.md             Explains the Terraform layout
│   ├── bootstrap/            S3 bucket for Terraform state (local state)
│   ├── modules/vpc/          Reusable VPC code
│   └── envs/
│       ├── dev/vpc/          Dev VPC stack (live)
│       └── prod/vpc/         Prod VPC stack (defined, never applied)
└── docs/
    ├── checklist.md          Done, left to do, and the cleanup reference
    └── avoid.md              The lab guide. Ignored by git, local only
```

## Things that differ from the lab guide

- The API is in `app/`, not at the repository root. The workflow runs npm in
  `app/` and builds the image with `app` as the Docker context.
- The network (Phase 6) is built with Terraform, not the console wizard.
- The dev VPC is named `ecs-lab-dev`. The guide calls it `ecs-lab-vpc`.
- `ecs-lab-api` is the name of the ECR repository, ECS service and task
  definition. The GitHub repository is `ecs-fargate-cicd`.

## Commands

```bash
# App (run inside app/)
npm ci
npm run typecheck
npm test
npm run dev

# Terraform (run inside a stack, for example infra/terraform/envs/dev/vpc)
terraform plan
terraform apply
```

Terraform needs no `AWS_PROFILE` and no `-var-file`. The profile is set in
`backend.tf` and `<env>.auto.tfvars`, and the settings load automatically.

## AWS

- Profile `my-account`, Region `us-east-1`. Do not use other AWS profiles on
  this computer.
- The AWS account ID is private. It lives only in the `terraform.tfvars` file
  of each stack, which git ignores. Never put it in a commit, a pull request
  or any other public text. This repository is public.
- The account holds resources that are not part of the lab. Change or delete
  only resources whose names start with `ecs-lab`.
- The NAT gateway is billed by the hour.

## Terraform conventions

- Reusable code goes in `modules/<name>`. Stacks under `envs/` only call
  modules.
- One folder per component per environment: `envs/<env>/<stack>`. Each stack
  has its own state key, `<env>/<stack>/terraform.tfstate`.
- The `.tf` files of a stack are identical in every environment. Only
  `<env>.auto.tfvars` and the state key in `backend.tf` differ.
- Use community modules in the plain style of their registry example, pinned
  to an exact version.
- Template variable files are named `example.tfvars`.
- Read the plan before applying. Stop if it wants to destroy or replace
  something unexpected.
- The planned next stack is `backend` (load balancer, ECS cluster and
  service): `modules/backend` plus `envs/dev/backend`.

## Git workflow

- Changes go on a branch, then a pull request into `main`. Commit, push and
  merge only when asked.
- Pull requests are often merged by hand on GitHub. Check the pull request
  state and `git status` before branching or merging.
- Every push to `main` builds and pushes a new image to ECR.
- Actions in the workflow are pinned to full commit SHAs. Keep them pinned.

## Cleanup

When asked to clean up or finish the lab, follow "Cleanup reference for
Claude" in `docs/checklist.md`, in order, and confirm each group with the
user before deleting it.
