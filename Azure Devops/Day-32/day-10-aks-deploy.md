# Day 10 — Deploy to Azure Kubernetes Service (AKS)

> Goal: deploy the containerised app to AKS from the pipeline.

---

## Objectives

By the end of this day you will:

- Create an AKS cluster and connect to it
- Write Kubernetes deployment and service manifests
- Deploy from the pipeline using kubectl
- Verify, scale, and roll back a deployment

---

## Concepts

### Kubernetes essentials

- Pods, ReplicaSets, Deployments, Services
- Manifests describe desired state declaratively
- kubectl apply reconciles actual to desired state

### AKS + ACR

- AKS pulls images from ACR (attach ACR to the cluster)
- Ingress + Load Balancer expose the app
- Namespaces separate environments

### Operations

- Scale replicas up/down; use HPA for autoscaling
- Roll out and roll back deployments safely

---

## Hands-on

1. Create an AKS cluster and get credentials
2. Write deployment.yaml and service.yaml
3. Add a kubectl apply step to the pipeline
4. Scale the deployment and then roll it back

---

## Commands / snippets

```
az aks create -g <rg> -n <cluster> --node-count 2 --attach-acr <registry>
az aks get-credentials -g <rg> -n <cluster>
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl get pods,svc
kubectl rollout undo deployment/app
```

> Add your own notes, screenshots, and expanded examples in this section.

---

## Homework

- Expose the app via a LoadBalancer or Ingress
- Add a Horizontal Pod Autoscaler
- Deploy to a staging namespace, then prod

---

## Recap

- AKS runs your containers in production
- Manifests declare desired state; kubectl applies it
- Scaling and rollbacks are first-class operations
- Next: provision all of this with Infrastructure as Code

