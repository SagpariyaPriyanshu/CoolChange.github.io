# Cool Change — Infrastructure as Code

Terraform scripts for the Cool Change cloud infrastructure (AWS, ap-southeast-4 /
Melbourne). Lives at `root/architecture/iac-scripts/` in the monorepo.

Decisions behind these choices (region, no NAT gateway, Terraform over other
IaC tools, etc.) are tracked in the project's Architecture Decisions Log, not
duplicated here — check that first if something here seems unexplained.

## Layout

```
iac-scripts/
├── bootstrap/          one-time setup: S3 state bucket + DynamoDB lock table
├── environments/
│   └── dev/            the dev environment config (this iteration's target)
└── modules/             reusable building blocks, one per later phase
    ├── networking/       Phase 1
    ├── iam/              Phase 2
    ├── database/         Phase 3
    ├── compute/          Phase 4
    ├── loadbalancer/      Phase 5
    ├── frontend/         Phase 6
    └── secrets/          Phase 7
```

Modules are currently empty placeholders — each gets built out when its
phase starts, then wired into `environments/dev/main.tf`.

## Prerequisites

- Terraform >= 1.7.0
- AWS CLI configured with credentials for the team's AWS account
- Your AWS user/role needs permission to create the resources each phase
  touches; Phase 0 itself only needs S3 + DynamoDB access for the bootstrap step

## First-time setup (run once, ever)

```bash
cd bootstrap
terraform init
terraform plan     # review what it would create
terraform apply    # creates the remote state bucket + lock table
```

## Working in an environment (dev, for now)

```bash
cd environments/dev
terraform init      # connects to the remote backend set up above
terraform plan       # ALWAYS review this before applying — nothing gets
                     # applied without a reviewed plan, per our iterative
                     # build approach
terraform apply
```

Never run `terraform apply` without reading the `plan` output first — that's
the whole point of building this phase by phase.

## Conventions

- Naming: `coolchange-<environment>-<resource>` (e.g. `coolchange-dev-vpc`)
- Tags: every resource gets `Project`, `Iteration`, `Environment`, `ManagedBy`
  automatically via the provider's `default_tags` (see `environments/dev/locals.tf`)
- Secrets never go in `.tfvars` files that get committed — see `.gitignore`
- One phase, one PR: don't bundle multiple phases' resources into a single
  `apply`
