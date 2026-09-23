# Day 06 — Build, Test & Code Quality in Pipelines

> Goal: compile a real app, run automated tests, and publish results and coverage.

---

## Objectives

By the end of this day you will:

- Restore dependencies and build a real application
- Run unit tests and publish test results
- Publish code coverage and build artifacts
- Add a basic code-quality/lint gate

---

## Concepts

### Real build steps

- Restore → build → test → publish artifacts
- Language-specific tasks (npm, dotnet, maven, python)
- Cache dependencies to speed up runs

### Test & coverage reporting

- Publish test results (JUnit/xUnit formats)
- Publish coverage (Cobertura) to the run summary
- Fail the build when tests fail or coverage drops

### Quality gates

- Linters/static analysis catch issues before review
- Optionally integrate SonarCloud or similar

---

## Hands-on

1. Add restore + build steps for your stack
2. Add a test step and publish the results
3. Publish a build artifact for later stages
4. Add a lint step that fails on violations

---

## Commands / snippets

```
steps:
  - script: npm ci
    displayName: Install
  - script: npm run build
    displayName: Build
  - script: npm test -- --ci --reporters=jest-junit
    displayName: Test
  - task: PublishTestResults@2
    inputs:
      testResultsFiles: '**/junit.xml'
```

> Add your own notes, screenshots, and expanded examples in this section.

---

## Homework

- Get test results showing in the run's Tests tab
- Publish coverage and set a minimum threshold
- Add caching for your package manager

---

## Recap

- CI now builds and tests a real app, not just echoes
- Results, coverage, and artifacts are visible per run
- Quality gates block bad changes early
- Next: manage shared packages with Azure Artifacts

