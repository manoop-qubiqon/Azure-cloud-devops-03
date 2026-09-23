# Day 09 — Continuous Delivery — Environments & Releases

> Goal: promote builds through dev → staging → prod with approvals.

---

## Objectives

By the end of this day you will:

- Define multiple deployment stages
- Use environments with approvals and checks
- Manage per-environment configuration and secrets
- Understand deployment strategies

---

## Concepts

### CD pipeline stages

- Deploy the same build artifact to each environment
- dev (auto) → staging (auto/approval) → prod (approval)
- Environments track deployment history

### Approvals & checks

- Manual approvals gate promotion to sensitive environments
- Checks: business hours, required reviewers, gates

### Config & secrets

- Per-environment variables and variable groups
- Pull secrets from Azure Key Vault, never hardcode
- Deployment strategies: rolling, blue-green, canary

---

## Hands-on

1. Add deploy stages for dev and staging to the pipeline
2. Create an environment with a required approval
3. Use a variable group for environment config
4. Promote a build from dev to staging

---

## Commands / snippets

```
stages:
  - stage: Deploy_Dev
    jobs:
      - deployment: deploy
        environment: dev
        strategy:
          runOnce:
            deploy:
              steps:
                - script: echo "Deploying to dev"
```

> Add your own notes, screenshots, and expanded examples in this section.

---

## Homework

- Add a prod stage protected by a manual approval
- Wire a variable group and a Key Vault-backed secret
- Write a short note comparing blue-green vs canary

---

## Recap

- CD promotes one artifact through environments safely
- Approvals and checks control sensitive deployments
- Config and secrets stay per-environment and secure
- Next: deploy to a real Kubernetes cluster (AKS)

