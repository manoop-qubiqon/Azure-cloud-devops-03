# Day 07 — Azure Artifacts & Package Management

> Goal: create feeds, publish packages, and consume them from pipelines.

---

## Objectives

By the end of this day you will:

- Understand feeds and upstream sources
- Publish a package to an Azure Artifacts feed
- Consume the package from another project/pipeline
- Apply versioning and retention

---

## Concepts

### Feeds & packages

- A feed hosts packages: npm, NuGet, Maven, Python, Universal
- Scope: project-level or organisation-level
- Upstream sources proxy public registries (npmjs, NuGet, PyPI)

### Publish & consume

- Authenticate the pipeline to the feed
- Push built packages; restore them in other builds
- Share internal libraries across teams

### Versioning & retention

- Semantic versioning for predictable upgrades
- Retention policies clean up old versions

---

## Hands-on

1. Create a feed named `shared`
2. Publish a small library package to it
3. Consume that package from a second pipeline
4. Add an upstream source for the public registry

---

## Commands / snippets

```
# Example: authenticate and publish an npm package
steps:
  - task: npmAuthenticate@0
    inputs:
      workingFile: .npmrc
  - script: npm publish
    displayName: Publish package
```

> Add your own notes, screenshots, and expanded examples in this section.

---

## Homework

- Publish two versions of a package and consume a specific one
- Configure a retention policy on the feed
- Document how a teammate would consume your feed

---

## Recap

- Artifacts centralises package hosting and sharing
- Feeds + upstreams unify internal and public packages
- Versioning keeps dependencies predictable
- Next: containerise the app with Docker and ACR

