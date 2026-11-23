# ECS Fargate lab: progress checklist

Last updated: 23 November 2026, after Phase 6.

This file tracks what is done, what is left, and how each part is done. The
last section is the cleanup reference for Claude to follow at the end of the lab.

The phase numbers follow the lab guide in `docs/avoid.md`, which is ignored by
git and exists only on the lab owner's computer.

## Fixed facts

| Item | Value |
| --- | --- |
| GitHub repository | `DaniyalManzoor/ecs-fargate-cicd` |
| AWS Region | `us-east-1` (N. Virginia) |
| AWS CLI profile | `my-account` |
| AWS account ID | In `terraform.tfvars` of each stack (ignored by git). Never commit it. |
| ECR repository | `ecs-lab-api` |
| GitHub Actions role | `ecs-lab-github-actions` |
| Terraform state bucket | `ecs-lab-tfstate-04c8bbc2` |
| Dev VPC name | `ecs-lab-dev` (the guide calls it `ecs-lab-vpc`) |

## How we work

- **Code changes:** create a branch, push it, open a pull request into `main`,
  wait for **Typecheck and test** to pass, then merge. Every push to `main`
  builds a new image and pushes it to ECR.
- **Terraform:** change into the stack folder and run `terraform plan`, then
  `terraform apply`. No `AWS_PROFILE` or `-var-file` is needed. Read the plan
  before applying; stop if it wants to destroy or replace something unexpected.
  The layout is explained in `infra/terraform/README.md`.
- **Console steps:** done by hand in the AWS console, following the guide.
- **Billing:** the NAT gateway is billed by the hour. To pause the lab, run
  `terraform destroy` in `infra/terraform/envs/dev/vpc`, and `terraform apply`
  to bring the network back. Do this only while no load balancer or ECS
  service uses the VPC.

## Done

### Phase 0: Before you start

- [x] 0.1 Sign in as an IAM user, not root (console)
- [x] 0.2 Region `us-east-1` chosen
- [x] 0.4 Budget alert of 10 USD a month (console)

### Phase 1: Build the API

- [x] Fastify API in TypeScript under `app/`, with three tests and a
      multi-stage Dockerfile that runs as a non-root user

The guide puts the API at the repository root. Here it is in `app/`.

### Phase 2: Put the code on GitHub

- [x] Public repository created and code pushed
- [x] Pull request 1 merged: API and pipeline

### Phase 3: ECR repository (console)

- [x] 3.1 Repository `ecs-lab-api` with immutable tags
- [x] 3.2 Scan on push for the whole registry (basic scanning)
- [x] 3.3 Lifecycle policy: keep the 10 newest images

### Phase 4: GitHub Actions can assume an IAM role (console)

- [x] 4.1 OIDC identity provider `token.actions.githubusercontent.com`
- [x] 4.2 Repository ID and owner ID found
- [x] 4.3 Role `ecs-lab-github-actions`, trusted only for the `main` branch of
      this repository, using the subject format with IDs
- [x] 4.4 Inline policy `ecr-push` on the role
- [x] 4.5 Repository variables `AWS_REGION`, `AWS_ROLE_ARN`, `ECR_REPOSITORY`

### Phase 5: Pipeline and first image

- [x] 5.1 `.github/workflows/deploy.yml`, adapted to the `app/` folder
- [x] 5.2 Pipeline green on `main`
- [x] 5.3 Image in ECR, tagged with the commit SHA
- [x] Extra: ECR scan findings fixed with `apk upgrade` in the Dockerfile
      (pull request 2). The scan of the newer image has not been checked yet.

### Phase 6: Network (Terraform, not the console wizard)

- [x] State bucket created by `infra/terraform/bootstrap`
- [x] Reusable module `infra/terraform/modules/vpc`
- [x] Dev VPC applied from `infra/terraform/envs/dev/vpc`: two public and two
      private subnets, one NAT gateway, S3 gateway endpoint
- [x] State stored in S3 at `dev/vpc/terraform.tfstate`, with lock files
- [x] Prod stack defined in `infra/terraform/envs/prod/vpc`. It is **not
      applied** and nothing in AWS exists for it.
- [x] Pull request 3 merged: Terraform for the VPC

## Left to do

### Loose ends

- [ ] Check the ECR scan result of the newest image
- [ ] Delete the merged branches `add-typescript-api`,
      `fix-image-scan-findings` and `add-network-terraform` (optional)

### Phase 7: Security groups and load balancer

Planned method: Terraform, in a new module `modules/backend` and a new stack
`envs/dev/backend`. The stack reads the VPC outputs from the state at
`dev/vpc/terraform.tfstate`.

- [ ] 7.1 Security groups: one for the load balancer, one for the tasks
- [ ] 7.2 Target group on port 3000 with health check `/health`
- [ ] 7.3 Load balancer `ecs-lab-alb` and its listener on port 80
- [ ] 7.4 Drop requests with invalid headers

### Phase 8: ECS roles, log group, cluster and task definition

- [ ] 8.1 Task execution role `ecs-lab-task-execution`
- [ ] 8.2 Task role `ecs-lab-task`
- [ ] 8.3 Log group `/ecs/ecs-lab-api`, kept 30 days
- [ ] 8.4 Cluster `ecs-lab-cluster`
- [ ] 8.5 Task definition `ecs-lab-api`

### Phase 9: Run the service

- [ ] 9.1 Service `ecs-lab-api` in the private subnets
- [ ] 9.2 Service is stable
- [ ] 9.3 The API answers through the load balancer

### Phase 10: Continuous deployment

- [ ] 10.1 Add deploy permissions to `ecs-lab-github-actions`
- [ ] 10.2 Repository variables `ECS_CLUSTER` and `ECS_SERVICE`
- [ ] 10.3 Ship a change through the pipeline
- [ ] 10.4 Watch the rolling update

If the service is managed by Terraform, the pipeline also changes its task
definition. Tell Terraform to ignore the task definition of the service, or
each `terraform apply` will roll the service back.

### Phase 11: Logs drill

- [ ] 11.1 to 11.6 Read logs, filter errors, query with Logs Insights, read
      service events, see why a task stopped

### Phase 12: Rollback drills

- [ ] 12.1 to 12.4 Ship a release that cannot start, and fix forward
- [ ] 12.5 Stop a deployment by hand
- [ ] 12.6 to 12.9 Ship a release that is healthy but wrong, and roll back

### Phase 13: Auto scaling

- [ ] 13.1 Smallest and largest task count
- [ ] 13.2 Target tracking policy

### Cleanup

- [ ] Run the cleanup reference below on the day the lab is finished

## Cleanup reference for Claude

Follow this section when the lab owner asks to clean up. Work through it in
order. Each step removes something the next one depends on.

### Rules

1. Confirm the account first. Run
   `aws sts get-caller-identity --profile my-account` and compare the account
   with `aws_account_id` in `infra/terraform/envs/dev/vpc/terraform.tfvars`.
   Stop if they differ.
2. Use the profile `my-account` and the Region `us-east-1` for every command.
   Do not use any other AWS profile on this computer.
3. Delete only resources of this lab. Their names start with `ecs-lab` or
   `/ecs/ecs-lab`, or they are listed in this file. The account holds other
   resources that are not part of the lab: several Lambda policies, a policy
   whose name starts with `s3crr_for_demo`, and the two budgets. Leave them.
4. Before each group below, list what exists and show it to the lab owner.
   Delete only after they confirm that group.
5. Before every `terraform destroy`, read the plan. It must list only
   resources of the stack you are in.
6. Skip any step whose resources were never created. Check the lists in this
   file and in AWS; do not assume.

### Step 1: Resources built on top of the VPC (Phases 7 to 13)

If these were created with Terraform in `infra/terraform/envs/dev/backend`,
run `terraform destroy` there and go to step 2.

If they were created in the console, delete them in this order:

1. ECS service `ecs-lab-api` in cluster `ecs-lab-cluster`, with force delete.
   Wait until it is gone. This also removes its auto scaling.
2. Every revision of the task definition `ecs-lab-api`: deregister.
3. CloudWatch alarms whose names start with
   `TargetTracking-service/ecs-lab-cluster/ecs-lab-api`.
4. Load balancer `ecs-lab-alb`, then target group `ecs-lab-tg`.
5. Cluster `ecs-lab-cluster`.
6. The two security groups made in Phase 7, for example `ecs-lab-alb-sg`.
   Terraform cannot delete the VPC while they exist.

### Step 2: The dev network

```bash
cd infra/terraform/envs/dev/vpc
terraform destroy
```

This removes the NAT gateway, its Elastic IP, the subnets, the route tables,
the internet gateway, the S3 endpoint and the VPC `ecs-lab-dev`. If it fails
because network interfaces still exist, the load balancer or the tasks are
still shutting down. Wait a minute and run it again.

### Step 3: The prod network

Prod was never applied when this file was written. Check before doing anything:

```bash
cd infra/terraform/envs/prod/vpc
terraform state list
```

An empty list means there is nothing to remove. If it lists resources, run
`terraform destroy` there.

### Step 4: Prove that nothing billed by the hour is left

All three lists must be empty in `us-east-1`. A NAT gateway in the state
`deleted` counts as empty.

```bash
aws ec2 describe-nat-gateways --profile my-account --region us-east-1 \
  --query 'NatGateways[?State!=`deleted`].[NatGatewayId,State]' --output text
aws elbv2 describe-load-balancers --profile my-account --region us-east-1 \
  --query 'LoadBalancers[].LoadBalancerName' --output text
aws ec2 describe-addresses --profile my-account --region us-east-1 \
  --query 'Addresses[].PublicIp' --output text
```

### Step 5: Logs, images and IAM

1. CloudWatch log groups `/ecs/ecs-lab-api` and
   `/aws/ecs/containerinsights/ecs-lab-cluster/performance`, if they exist.
2. ECR repository `ecs-lab-api`, with all its images.
3. IAM roles `ecs-lab-github-actions`, `ecs-lab-task-execution` and
   `ecs-lab-task`. Remove their inline and attached policies first. The
   policy `ecr-push` is inline on `ecs-lab-github-actions`.
4. IAM identity provider `token.actions.githubusercontent.com`. Ask the lab
   owner first: skip this if any other project in the account uses GitHub
   OIDC.

Keep the budgets. They cost nothing.

### Step 6: The Terraform state bucket

Do this last, and only after steps 2 and 3 left no resources in any state.

1. The bucket `ecs-lab-tfstate-04c8bbc2` is versioned. Delete every object
   version and every delete marker in it.
2. In `infra/terraform/bootstrap/main.tf`, remove the `prevent_destroy` block
   from `aws_s3_bucket.state`.
3. Run `terraform destroy` in `infra/terraform/bootstrap`. Its state is the
   local file `terraform.tfstate` in that folder.

The bucket costs almost nothing. If the lab owner wants to keep the Terraform
setup for later, skip this step.

### Step 7: GitHub and this computer

1. Disable the workflow `build-and-deploy` in the **Actions** tab. With the
   role gone, the next push to `main` would fail at the credentials step.
2. Optional: delete the repository variables `AWS_REGION`, `AWS_ROLE_ARN`,
   `ECR_REPOSITORY`, `ECS_CLUSTER` and `ECS_SERVICE`.
3. Optional: remove the local Docker image with
   `docker rmi ecs-lab-api:scan-fix`.
4. Optional: delete the `.terraform` folders under `infra/terraform`. They
   hold the downloaded AWS provider and can be recreated with `terraform init`.

### Step 8: Report

Tell the lab owner what was deleted, what was skipped and why, and the output
of the three checks in step 4. Then tick the cleanup item in this file.
