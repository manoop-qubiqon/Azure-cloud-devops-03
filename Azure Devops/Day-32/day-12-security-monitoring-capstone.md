# Day 12 — Security, Monitoring & the Capstone Project

> Goal: add security scanning and monitoring, then assemble the full end-to-end project.

---

## Objectives

By the end of this day you will:

- Add security scanning (SAST, dependency, image) to the pipeline
- Manage secrets with Azure Key Vault
- Set up monitoring with Azure Monitor & Log Analytics
- Build the complete Boards-to-Production capstone

---

## Concepts

### Security in the pipeline (DevSecOps)

- Static analysis (SAST) on code
- Dependency and container image scanning
- Secrets from Key Vault, never in code or logs

### Monitoring & observability

- Azure Monitor + Application Insights for app telemetry
- Log Analytics + KQL to query logs
- Alerts and dashboards for production health

### Capstone architecture

- Boards → Repos → PR → CI → security scan → Docker → ACR → AKS → prod
- IaC provisions the infrastructure; monitoring closes the loop

---

## Hands-on

1. Add a SAST and dependency-scan step to CI
2. Store a secret in Key Vault and consume it in a deploy stage
3. Enable Application Insights and view live telemetry
4. Assemble all stages into one working end-to-end pipeline

---

## Commands / snippets

```
# Reference commands used across the capstone
git push origin main
docker build -t <registry>.azurecr.io/app:$(Build.BuildId) .
docker push <registry>.azurecr.io/app:$(Build.BuildId)
kubectl apply -f deployment.yaml
terraform apply -auto-approve
```

> Add your own notes, screenshots, and expanded examples in this section.

---

## Homework

- Ship one change from a Board work item all the way to production
- Add an alert rule that fires on error-rate spikes
- Write a one-page architecture summary of your capstone

---

## Recap

- Security and monitoring are part of the pipeline, not afterthoughts
- Key Vault keeps secrets out of code
- The capstone ties every service together end to end
- You've gone from DevOps fundamentals to a full CI/CD project — zero to hero.

