# Sources

The rules in this skill were collected from these guides on 23 November 2026.
Check the source when a rule matters and the guide may have changed.

## Google Cloud: Best practices for using Terraform

Written for Google Cloud, but most rules apply to any provider.

- General style and structure: https://docs.cloud.google.com/docs/terraform/best-practices/general-style-structure
- Reusable modules: https://docs.cloud.google.com/docs/terraform/best-practices/reusable-modules
- Root modules: https://docs.cloud.google.com/docs/terraform/best-practices/root-modules
- Dependency management: https://docs.cloud.google.com/docs/terraform/best-practices/dependency-management
- Cross-configuration communication: https://docs.cloud.google.com/docs/terraform/best-practices/cross-config-communication
- Version control: https://docs.cloud.google.com/docs/terraform/best-practices/version-control
- Operations: https://docs.cloud.google.com/docs/terraform/best-practices/operations
- Security: https://docs.cloud.google.com/docs/terraform/best-practices/security
- Testing: https://docs.cloud.google.com/docs/terraform/best-practices/testing

## HashiCorp

- Terraform style guide: https://developer.hashicorp.com/terraform/language/style
- Standard module structure: https://developer.hashicorp.com/terraform/language/modules/develop/structure

## AWS Prescriptive Guidance: Best practices for using the Terraform AWS Provider

- Structure and naming: https://docs.aws.amazon.com/prescriptive-guidance/latest/terraform-aws-provider-best-practices/structure.html
- Security: https://docs.aws.amazon.com/prescriptive-guidance/latest/terraform-aws-provider-best-practices/security.html
- Backend: https://docs.aws.amazon.com/prescriptive-guidance/latest/terraform-aws-provider-best-practices/backend.html
- Version management: https://docs.aws.amazon.com/prescriptive-guidance/latest/terraform-aws-provider-best-practices/version.html

## terraform-best-practices.com (Anton Babenko, on GitHub)

By the maintainer of the `terraform-aws-modules` collection.

- Repository: https://github.com/antonbabenko/terraform-best-practices
- Naming: https://www.terraform-best-practices.com/naming
- Code structure: https://www.terraform-best-practices.com/code-structure
- Code styling: https://www.terraform-best-practices.com/code-styling
- Pre-commit hooks: https://github.com/antonbabenko/pre-commit-terraform

## Rules left out on purpose

- Rules that apply only to Google Cloud, such as enabling APIs, Cloud Storage
  backends and `gcloud terraform vet`.
- Rules that apply only to HCP Terraform or Terraform Enterprise, such as
  workspaces per environment, Sentinel policy sets and dynamic provider
  credentials. This repository uses the open-source CLI with an S3 backend.
- Google's rule of one branch per environment. HashiCorp's guide and this
  repository use one directory per environment instead.
