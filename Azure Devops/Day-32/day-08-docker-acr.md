# Day 08 — Containers — Docker & Azure Container Registry

> Goal: containerise the app and push images to Azure Container Registry (ACR).

---

## Objectives

By the end of this day you will:

- Write an efficient multi-stage Dockerfile
- Build and run the image locally
- Create an ACR and push the image
- Build and push images from a pipeline

---

## Concepts

### Docker basics

- Image = packaged app + dependencies; container = running instance
- Layers and caching speed up rebuilds
- Multi-stage builds keep final images small

### Azure Container Registry

- Private registry for your images
- Authenticate pipelines via service connection
- Tagging strategy (e.g. :v1, :$(Build.BuildId), :latest)

### Images in CI

- Build image → run tests → push to ACR on success
- Immutable, versioned artifacts ready to deploy

---

## Hands-on

1. Write a multi-stage Dockerfile for the app
2. Build and run it locally, verify it serves
3. Create an ACR and push the image manually
4. Add a Docker build+push task to the pipeline

---

## Commands / snippets

```
docker build -t app:local .
docker container run -p 3000:3000 app:local
az acr create -n <registry> -g <rg> --sku Basic
az acr login -n <registry>
docker tag app:local <registry>.azurecr.io/app:v1
docker push <registry>.azurecr.io/app:v1
```

> Add your own notes, screenshots, and expanded examples in this section.

---

## Homework

- Reduce the final image size using multi-stage builds
- Tag images with the build ID and push automatically
- Scan the image for vulnerabilities

---

## Recap

- Containers make deployments consistent across environments
- Multi-stage Dockerfiles produce lean images
- ACR stores your private, versioned images
- Next: promote releases across environments (CD)

