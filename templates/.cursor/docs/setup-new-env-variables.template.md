# Variables for setup-new-env

Fill in the values below, then copy the "Block to paste in prompt" into Cursor chat (after copying the main prompt from setup-new-env.md).

---

## Form to fill

| Variable | Your value |
|----------|------------|
| PROJECT_NAME | |
| REPOS | |
| REPO_PATHS | |
| LANGUAGES | |
| BUILD_TOOLS | |
| LINTERS | |
| TEST_FRAMEWORKS | |
| CLOUD_PROVIDER | |
| ISSUE_TRACKER | |
| VCS | |
| NOTIFICATION_CHANNEL | |
| ENGINEER_PROFILE | |

---

## Block to paste in prompt

Once filled, copy this block and replace the values between `<>`:

```
- PROJECT_NAME: <your_project>
- REPOS: <back, front, data>
- REPO_PATHS: <{{REPO_BACK_NAME}}, {{REPO_FRONT_NAME}}, {{REPO_DATA_NAME}}>
- LANGUAGES: <back: Java, front: TypeScript, data: Python>
- BUILD_TOOLS: <back: Gradle, front: npm, data: Poetry>
- LINTERS: <back: checkstyle, front: ESLint, data: ruff>
- TEST_FRAMEWORKS: <back: JUnit, front: Jest, data: pytest>
- CLOUD_PROVIDER: <azure|aws|gcp|none>
- ISSUE_TRACKER: <jira|github-issues|linear|none>
- VCS: <github|gitlab|azure-devops>
- NOTIFICATION_CHANNEL: <teams|slack|none>
- ENGINEER_PROFILE: <back|front|fullstack|data-science|devops|ml-ops>

If a variable is empty, infer it from workspace analysis.
```

---

## Pre-filled examples

### Fullstack ({{PROJECT_NAME}})

```
- PROJECT_NAME: {{PROJECT_NAME}}
- REPOS: back, front, data
- REPO_PATHS: {{REPO_BACK_NAME}}, {{REPO_FRONT_NAME}}, {{REPO_DATA_NAME}}
- LANGUAGES: back: Java, front: TypeScript, data: Python
- BUILD_TOOLS: back: Gradle, front: npm, data: Poetry
- LINTERS: back: checkstyle, front: ESLint, data: ruff
- TEST_FRAMEWORKS: back: JUnit, front: Jest, data: pytest
- CLOUD_PROVIDER: azure
- ISSUE_TRACKER: jira
- VCS: github
- NOTIFICATION_CHANNEL: teams
- ENGINEER_PROFILE: fullstack

If a variable is empty, infer it from workspace analysis.
```

### Data science

```
- PROJECT_NAME: MLPipeline
- REPOS: notebooks, training, serving
- REPO_PATHS: notebooks, ml-training, ml-serving
- LANGUAGES: notebooks: Python, training: Python, serving: Python
- BUILD_TOOLS: notebooks: pip, training: Poetry, serving: Docker
- LINTERS: ruff, mypy
- TEST_FRAMEWORKS: pytest
- CLOUD_PROVIDER: gcp
- ISSUE_TRACKER: github-issues
- VCS: github
- NOTIFICATION_CHANNEL: slack
- ENGINEER_PROFILE: data-science

If a variable is empty, infer it from workspace analysis.
```

### DevOps / Infra

```
- PROJECT_NAME: InfraRepo
- REPOS: terraform, helm, ansible
- REPO_PATHS: terraform, helm-charts, ansible-playbooks
- LANGUAGES: terraform: HCL, helm: YAML, ansible: YAML
- BUILD_TOOLS: terraform: terraform, helm: helm, ansible: ansible
- LINTERS: tflint, yamllint
- TEST_FRAMEWORKS: terratest, molecule
- CLOUD_PROVIDER: aws
- ISSUE_TRACKER: jira
- VCS: github
- NOTIFICATION_CHANNEL: none
- ENGINEER_PROFILE: devops

If a variable is empty, infer it from workspace analysis.
```
