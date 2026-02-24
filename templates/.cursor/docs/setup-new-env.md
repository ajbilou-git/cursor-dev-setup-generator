# Prompt: Configure a Cursor environment for a new project

Copy this prompt into Cursor so it analyzes your code and builds a complete `.cursor` setup, aligned with DevOps best practices and adapted to your tech stack.

---

## Configuration variables (fill before use)

> **Dedicated file**: use `docs/setup-new-env-variables.template.md` to fill in variables and copy ready-to-use blocks (with fullstack, data-science, devops examples).

Fill in the table below according to your context. The agent will use these values to customize the setup.

| Variable | Description | Examples |
|----------|-------------|----------|
| `{{PROJECT_NAME}}` | Project name | `{{PROJECT_NAME}}`, `DataPipeline`, `MLService` |
| `{{REPOS}}` | List of repos/modules in the workspace | `back`, `front`, `data`, `infra` or `api`, `web`, `ml`, `terraform` |
| `{{REPO_PATHS}}` | Relative paths to each repo | `{{REPO_BACK_NAME}}`, `{{REPO_FRONT_NAME}}` or `packages/api`, `apps/web` |
| `{{LANGUAGES}}` | Languages per repo | `back: Java`, `front: TypeScript`, `data: Python` |
| `{{BUILD_TOOLS}}` | Build tools per repo | `back: Gradle`, `front: npm`, `data: Poetry` |
| `{{LINTERS}}` | Linters per repo | `back: checkstyle`, `front: ESLint`, `data: ruff` |
| `{{TEST_FRAMEWORKS}}` | Test frameworks per repo | `back: JUnit`, `front: Jest`, `data: pytest` |
| `{{CLOUD_PROVIDER}}` | Cloud provider (or none) | `azure`, `aws`, `gcp`, `none` |
| `{{ISSUE_TRACKER}}` | Issue tracking tool | `jira`, `github-issues`, `linear`, `none` |
| `{{VCS}}` | Version control | `github`, `gitlab`, `azure-devops` |
| `{{NOTIFICATION_CHANNEL}}` | Notification channel (or none) | `teams`, `slack`, `none` |
| `{{ENGINEER_PROFILE}}` | Target profile | `back`, `front`, `fullstack`, `data-science`, `devops`, `ml-ops` |

### Engineer profiles and typical mapping

| Profile | Typical repos | Typical stack |
|---------|---------------|---------------|
| **back** | `api`, `services` | Java/Kotlin, Spring, Gradle; Go, C# |
| **front** | `web`, `mobile`, `ui` | TypeScript, React/Vue/Angular, npm/pnpm |
| **fullstack** | `back`, `front`, `shared` | Back + Front combined |
| **data-science** | `notebooks`, `pipelines`, `models` | Python, Jupyter, pandas, scikit-learn |
| **devops** | `infra`, `terraform`, `helm` | Terraform, Ansible, Docker, Kubernetes |
| **ml-ops** | `training`, `serving`, `infra` | Python, MLflow, Docker, K8s |

---

## Prompt to paste in Cursor

```
You are a DevOps expert and workflow architect for development assistance. Analyze my project (structure, languages, tools, repos) and create a complete and coherent `.cursor` setup.

## Context variables (provided by the user)

The user has filled in the following variables. Use them to customize the setup:

- PROJECT_NAME: {{PROJECT_NAME}}
- REPOS: {{REPOS}}
- REPO_PATHS: {{REPO_PATHS}}
- LANGUAGES: {{LANGUAGES}}
- BUILD_TOOLS: {{BUILD_TOOLS}}
- LINTERS: {{LINTERS}}
- TEST_FRAMEWORKS: {{TEST_FRAMEWORKS}}
- CLOUD_PROVIDER: {{CLOUD_PROVIDER}}
- ISSUE_TRACKER: {{ISSUE_TRACKER}}
- VCS: {{VCS}}
- NOTIFICATION_CHANNEL: {{NOTIFICATION_CHANNEL}}
- ENGINEER_PROFILE: {{ENGINEER_PROFILE}}

If a variable is empty, infer it from workspace analysis.

## Objective

Produce a `.cursor/` directory structure with:
- **Rules**: competences and restrictions
- **Skills**: reusable agent workflows
- **Docs**: local setup and troubleshooting guides
- **Reports**: directories for agent outputs

## Steps to follow

### 1. Analyze the project

Scan the workspace and identify:
- **Repos / modules**: according to REPOS and REPO_PATHS
- **Tech stack**: LANGUAGES, BUILD_TOOLS, databases, containers
- **Tools**: LINTERS, formatters, TEST_FRAMEWORKS
- **Integrations**: ISSUE_TRACKER, VCS, CLOUD_PROVIDER, NOTIFICATION_CHANNEL
- **Environment variables**: tokens, secrets, required configs (e.g. NPM_AUTH_TOKEN, AWS_*, GCP_*)

### 2. Create the rules

#### 2a. Rules `competences/` (per domain or repo)

For each identified repo/module, create `.cursor/rules/competences/<repo-name>-conventions.mdc`:

```yaml
---
description: Conventions for <repo-name> (<stack>)
globs: <repo-path>/**/*
alwaysApply: false
---

# <repo-name> - Conventions

## Stack
- Language, framework, build, linter, tests (according to LANGUAGES, BUILD_TOOLS, LINTERS, TEST_FRAMEWORKS)

## Naming
- camelCase / snake_case / PascalCase according to repo language

## Structure
- Directory and file organization

## Build and Test
\`\`\`bash
<lint, build, test commands adapted to BUILD_TOOL and TEST_FRAMEWORK>
\`\`\`

## Rules
- Project-specific conventions
```

**Global rule**: create `devops-senior-engineer.mdc` (or equivalent) with `alwaysApply: true` for general DevOps principles (modularity, IaC, security, naming). Adapt content according to ENGINEER_PROFILE (e.g. ML/Data focus for data-science).

**Code review tool rule** (if used): `coderabbit-cli.mdc` or equivalent with command and execution limit.

#### 2b. Rules `restrictions/` (security policies)

Create rules with `alwaysApply: true` for:

| Rule | Content |
|------|---------|
| `no-comments.mdc` | Do not add comments in code |
| `no-ai-meta-mention.mdc` | Never mention Cursor, agent, AI in commits, PRs, tickets, branches |
| `no-modify-existing.mdc` | Do not delete/modify existing resources (VCS, ISSUE_TRACKER, cloud) except those created in the session |
| `no-<vcs>-write.mdc` | VCS policy: signed commits, no push to main branch, no merge, no delete/update via MCP. Adapt per VCS (github, gitlab, etc.) |
| `no-<issue-tracker>-write.mdc` | ISSUE_TRACKER policy: read-only except create/assign/transition per workflow. Adapt per jira, github-issues, linear, etc. |
| `<cloud-provider>-read-only.mdc` | CLOUD_PROVIDER: read-only (list, get, query); no create/update/delete via CLI or MCP. Create only if CLOUD_PROVIDER != none (azure-read-only, aws-read-only, gcp-read-only) |

### 3. Create the skills

For each recurring agent workflow, create `.cursor/skills/<name>/` with a `SKILL.md`:

**SKILL.md structure**:

```markdown
---
name: <name>
description: <short description for trigger>
---

# <Name> (Agent)

## Trigger
- Phrases to trigger the agent

## Input
- Data provided by the user or pipeline

## Prerequisites (local env)
| Repo | Requirements |
|------|--------------|
| <repo-1> | Language, build, environment variables |
| <repo-2> | ... |

## Rules
- Constraints (language, signed commits, etc.)

## Workflow steps
1. Step 1
2. Step 2
...

## Output
- Expected summary format
```

**Skills to create depending on context**:

| Skill | When to create | Depends on |
|-------|----------------|------------|
| `dev-expert` | Ticket → implementation → tests → PR | ISSUE_TRACKER, REPOS |
| `dev-approval` | Re-test → review → approval | VCS |
| `dev-pipeline` | Orchestration dev-expert + dev-approval + report | ISSUE_TRACKER, NOTIFICATION_CHANNEL |
| `infra-bootstrap-workflow` | Align infra repo with reference repo | If multiple infra repos |
| `bootstrap-devops-expert` | Tech analysis, provider changelogs, report | If infra stack (Terraform, etc.) |
| `data-pipeline` | Run notebooks, train models | If ENGINEER_PROFILE = data-science or ml-ops |

Adapt names and content according to ENGINEER_PROFILE and repos.

### 4. Create the documentation

#### 4a. `docs/<profile>-local-setup.md`

File name according to ENGINEER_PROFILE: `fullstack-local-setup.md`, `back-local-setup.md`, `data-science-local-setup.md`, `devops-local-setup.md`, etc.

Complete guide to configure the local machine:

1. **Global prerequisites**: table (Tool | Version | Installation) according to LANGUAGES and BUILD_TOOLS
2. **Shell configuration**: variables to add to `{{SHELL_CONFIG_FILE}}` (tokens, paths)
3. **Per repo**: installation, environment variables, test commands, smoke
4. **Makefile summary**: setup, test, lint, smoke commands
5. **Post-installation verification**: validation commands
6. **Troubleshooting**: common errors and solutions

#### 4b. Report directories

- `.cursor/dev-reports/`: pipeline reports (e.g. `YYYY-MM-DD_HHmm_TICKET-XXX_result.md`)
- `.cursor/<name>-reports/`: other agent reports (e.g. bootstrap-devops-reports, data-pipeline-reports)
- Each directory with a descriptive `README.md`

### 5. Create or adapt the Makefile

At project root, create a `Makefile` with targets per repo:

```makefile
.PHONY: help setup-<repo> test-<repo> lint-<repo> smoke-<repo>

help:
	@echo "Commands aligned with agents"
	@echo "  make setup-<repo>   Install <repo>"
	@echo "  make test-<repo>    Lint + build + tests"
	@echo "  make lint-<repo>    Linter only"
	@echo "  make smoke-<repo>   Runtime verification"

setup-<repo>:
	cd <repo-path> && <installation commands per BUILD_TOOL>

test-<repo>:
	cd <repo-path> && <lint> && <build> && <tests>

lint-<repo>:
	cd <repo-path> && <linter>

smoke-<repo>:
	cd <repo-path> && <start server / health check / notebook>
```

Repeat for each repo in REPOS. Adapt commands according to BUILD_TOOLS and TEST_FRAMEWORKS (Gradle, npm, Poetry, go build, cargo, etc.).

### 6. Configuration files

- **`.env`** for skills: create a `.env.example` template at skill root, without sensitive values. Typical variables: `TEAMS_WEBHOOK_URL`, `SLACK_WEBHOOK_URL`, `JIRA_*`, `GITHUB_TOKEN`, `AWS_*`, `GCP_*`
- **`.gitignore`**: add `.cursor/skills/*/\.env` if needed

## Constraints to follow

1. **Language**: English for code, technical docs and rules
2. **No comments** in code (no-comments rule)
3. **Signed commits**: `git commit -S -m "message"`
4. **Terminal permissions**: agents must use `required_permissions: ["all"]` for build/test/git commands to avoid sandbox prompts
5. **Login shell**: to load environment variables, use `{{LOGIN_SHELL_CMD}} "..."`

## Expected deliverables

1. Complete `.cursor/` directory structure
2. Updated `docs/<profile>-local-setup.md` file
3. Makefile with all commands for each repo
4. Chat summary: structure created, key commands, environment variables to configure
```

---

## Usage

1. Fill in variables in `setup-new-env-variables.template.md` (or the table above) and copy the corresponding block
2. Open Cursor on your project
3. Copy the prompt block above (from "You are a DevOps expert…") and replace `{{VARIABLE}}` with your values
4. Paste in Cursor chat
5. The agent will analyze your code and generate the adapted `.cursor` setup
6. Manually verify and adjust paths, repo names and specific integrations

## Variable example (fullstack project like {{PROJECT_NAME}})

| Variable | Value |
|----------|-------|
| PROJECT_NAME | {{PROJECT_NAME}} |
| REPOS | back, front, data |
| REPO_PATHS | {{REPO_BACK_NAME}}, {{REPO_FRONT_NAME}}, {{REPO_DATA_NAME}} |
| LANGUAGES | back: Java, front: TypeScript, data: Python |
| BUILD_TOOLS | back: Gradle, front: npm, data: Poetry |
| LINTERS | back: checkstyle, front: ESLint, data: ruff |
| TEST_FRAMEWORKS | back: JUnit, front: Jest, data: pytest |
| CLOUD_PROVIDER | azure |
| ISSUE_TRACKER | jira |
| VCS | github |
| NOTIFICATION_CHANNEL | teams |
| ENGINEER_PROFILE | fullstack |

## Variable example (data science project)

| Variable | Value |
|----------|-------|
| PROJECT_NAME | MLPipeline |
| REPOS | notebooks, training, serving |
| REPO_PATHS | notebooks, ml-training, ml-serving |
| LANGUAGES | notebooks: Python, training: Python, serving: Python |
| BUILD_TOOLS | notebooks: pip, training: Poetry, serving: Docker |
| LINTERS | ruff, mypy |
| TEST_FRAMEWORKS | pytest |
| CLOUD_PROVIDER | gcp |
| ISSUE_TRACKER | github-issues |
| VCS | github |
| NOTIFICATION_CHANNEL | slack |
| ENGINEER_PROFILE | data-science |

## Reference: target structure

```
.cursor/
├── docs/
│   ├── <profile>-local-setup.md
│   ├── setup-new-env.md
│   └── setup-new-env-variables.template.md
├── rules/
│   ├── competences/
│   │   ├── devops-senior-engineer.mdc
│   │   ├── <repo>-conventions.mdc
│   │   └── coderabbit-cli.mdc
│   └── restrictions/
│       ├── no-comments.mdc
│       ├── no-ai-meta-mention.mdc
│       ├── no-modify-existing.mdc
│       ├── no-<vcs>-write.mdc
│       ├── no-<issue-tracker>-write.mdc
│       └── <cloud-provider>-read-only.mdc
├── skills/
│   ├── dev-expert/
│   │   ├── SKILL.md
│   │   └── reference.md
│   ├── dev-approval/
│   │   └── SKILL.md
│   ├── dev-pipeline/
│   │   ├── SKILL.md
│   │   └── .env.example
│   └── <other-skills>/
├── dev-reports/
│   └── README.md
└── <name>-reports/
    └── README.md
```
