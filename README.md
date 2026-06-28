# AWS DevSecOps Capstone — Production-Grade URL Shortener

A fully automated, reproducible AWS deployment of a real application, provisioned
entirely as code with Terraform and shipped through a secure CI/CD pipeline.

This project ties together the full DevSecOps stack: multi-AZ networking, container
orchestration, a managed database with secrets handled correctly, keyless CI/CD,
zero-downtime blue/green deployments, observability, a CDN with HTTPS, and scheduled
serverless automation — all tear-down-and-rebuild reproducible.

---

## The application

A small **URL shortener**: submit a long URL, get back a short code; visiting the
short code redirects to the original. Deliberately simple in code so the
**infrastructure** is the focus — but real enough that every AWS component earns
its place (it genuinely needs a database, a static front-end, an API, and cleanup).

---

## Architecture

```
                          ┌─────────────────────────┐
        Users  ──HTTPS──> │  CloudFront (CDN + TLS)  │
                          └───────────┬─────────────┘
                                      │ static page (HTML/JS form)
                          ┌───────────▼─────────────┐
                          │   S3 (static assets)     │
                          └─────────────────────────┘
                                      │ API calls (create / redirect)
                          ┌───────────▼─────────────┐
                          │   ALB (public subnets)   │
                          └───────────┬─────────────┘
                                      │
                          ┌───────────▼─────────────┐
                          │  ECS Fargate (private)   │  ← Flask API, blue/green
                          └───────────┬─────────────┘
                                      │ reads/writes
                          ┌───────────▼─────────────┐
                          │  RDS PostgreSQL (private)│  ← password in Secrets Manager
                          └─────────────────────────┘

   Scheduled Lambda ──> cleans up expired links / backups (EventBridge cron)
   CloudWatch ──> dashboards + alarms ──> SNS notifications
   GitHub Actions ──OIDC──> build → test → deploy (no stored credentials)
```

---

## Requirements checklist

- [ ] VPC (multi-AZ, public/private subnets) — Terraform
- [ ] App on ECS Fargate behind an ALB
- [ ] RDS database in private subnets, password in Secrets Manager
- [ ] CI/CD pipeline (GitHub Actions) using OIDC: build → test → deploy on push
- [ ] Blue/green deployment with automatic rollback
- [ ] CloudWatch dashboards + alarms → SNS alerts
- [ ] CloudFront + S3 for static assets, HTTPS via CloudFront/ACM
- [ ] Scheduled Lambda doing backups/cleanup
- [ ] Fully reproducible: `terraform destroy` then `terraform apply` rebuilds everything

---

## Build plan (layered)

Built incrementally, each layer a working, committed milestone:

| Layer | Component | Status |
|-------|-----------|--------|
| 1 | VPC — multi-AZ, public/private subnets, NAT | in progress |
| 2 | ECS Fargate + ALB + the app | todo |
| 3 | RDS PostgreSQL + Secrets Manager | todo |
| 4 | CI/CD pipeline (OIDC) + blue/green | todo |
| 5 | CloudWatch dashboards + alarms + SNS | todo |
| 6 | CloudFront + S3 + HTTPS | todo |
| 7 | Scheduled Lambda (cleanup/backup) | todo |
| 8 | Reproducibility verification + docs | todo |

---

## Security highlights

- **No long-lived credentials anywhere** — CI/CD authenticates to AWS via GitHub OIDC,
  assuming a least-privilege IAM role scoped to this repository.
- **Database password never in code** — generated and stored in AWS Secrets Manager,
  injected into the container at runtime.
- **Defence in depth** — database and application tasks live in private subnets with
  no inbound internet access; only the ALB is public, and security groups restrict
  traffic to the minimum required path.
- **HTTPS everywhere** at the edge via CloudFront.

---

## Tech stack

Terraform · AWS (VPC, ECS Fargate, ALB, RDS, Secrets Manager, CloudFront, S3, ACM,
Lambda, EventBridge, CloudWatch, SNS, ECR, IAM) · GitHub Actions · Docker · Python/Flask

---

## Reproducibility

The entire stack is defined in Terraform. To stand it up or tear it down:

```bash
cd terraform
terraform init
terraform apply     # builds the whole environment
terraform destroy   # removes everything, stops all billing
```

This is the core proof of the project: the environment can be destroyed and rebuilt
from code, identically, on demand.

---

*Author: Kehinde Adetunji · github.com/Kentunji*
