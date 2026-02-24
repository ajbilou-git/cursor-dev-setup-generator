---
name: infra-bootstrap-pipeline
description: End-to-end pipeline that runs infra-bootstrap-workflow then infra-bootstrap-plan-validator. Aligns {{REPO_INFRA_NAME}} with bootstrap releases, creates PR if needed, validates Terraform plan and stores summary. Use when the user wants full automation from alignment check to plan validation.
---

# Infra Bootstrap Pipeline (Orchestrator)

Automated flow: **infra-bootstrap-workflow** (align infra, create PR if needed) → **infra-bootstrap-plan-validator** (validate plan, create report) — only when a PR was created.

## How to launch

- *"Run the infra bootstrap pipeline"*
- *"Align {{REPO_INFRA_NAME}} with bootstrap and validate the plan end-to-end"*
- *"Execute infra-bootstrap-pipeline"*
- *"Full bootstrap alignment: align then validate plan"*

## Prerequisites

- Workspace includes `{{REPO_INFRA_NAME}}/`
- GitHub MCP + Jira MCP available
- `gh` CLI installed and authenticated (for plan validator)

## Rules

- **Language**: All outputs in **English**
- **Never** mention cursor, Cursor, AI, assistant or automation tools in commits, PRs, Jira or docs

## Pipeline Phases

### Phase 1: infra-bootstrap-workflow

Execute the full infra-bootstrap-workflow skill. Follow all steps from `.cursor/skills/ops/infra-bootstrap-workflow/SKILL.md`:

1. List bootstrap releases
2. Identify aligned version and releases to process
3. For each target release: fetch PR files, pre-apply analysis, apply changes
4. If changes needed: create Jira ticket, branch, commit, push, create PR

**Phase 1 output**:
- If PR created: Jira ticket key, PR number, PR URL, branch name, **root_layers**, **env_layers** (comma-separated from infra-bootstrap-workflow)
- If no changes: "No alignment needed" + aligned version

### Phase 2: infra-bootstrap-plan-validator (conditional)

**Run only if Phase 1 created a PR.**

Execute the full infra-bootstrap-plan-validator skill. Follow all steps from `.cursor/skills/ops/infra-bootstrap-plan-validator/SKILL.md`:

1. Use PR number from Phase 1
2. Find or trigger workflow 55-plan-modified-layers
3. Wait for run completion
4. Download artifacts
5. Parse and create report in `.cursor/bootstrap-align-reports/plan-summary-{date}-pr{num}.md`

**Phase 2 output**:
- Report path
- Workflow run URL
- Plan summary (create/update/delete/replace counts)
- Detailed table: Action | Resource | Description (per impacted resource)

## Error handling

| Situation | Action |
|-----------|--------|
| Phase 1: No releases to process | Stop. Output "Already aligned with latest bootstrap." |
| Phase 1: Pre-apply finds no applicable changes | Stop. Create changelog only, no PR. Skip Phase 2. |
| Phase 1: Jira/PR creation fails | Stop. Report error. Do not run Phase 2. |
| Phase 2: Workflow 55 fails | Report failure, link to run. Do not create doc. |
| Phase 2: No artifacts | Create doc with "Artifacts not available". |
| Phase 2: No run found after 2 min | Report. Suggest manual workflow_dispatch. |

## Critical: No manual steps

The agent MUST execute all commands directly. Use `required_permissions: ["all"]` for git, gh, and network operations. No human gate between phases.

## Concrete execution

### Phase 1 — infra-bootstrap-workflow

1. Read `.cursor/skills/ops/infra-bootstrap-workflow/SKILL.md` and execute all steps.
2. Capture output: `pr_number`, `branch`, `jira_key`, `root_layers`, `env_layers` (if PR created).
3. If no PR created (no changes or pre-apply found nothing applicable): stop pipeline, output "No alignment needed".

### Phase 2 — infra-bootstrap-plan-validator

1. Read `.cursor/skills/ops/infra-bootstrap-plan-validator/SKILL.md`.
2. Use `pr_number`, `branch`, `root_layers`, `env_layers` from Phase 1.
3. `cd {{REPO_INFRA_NAME}} && gh run list --workflow=55-plan-modified-layers.yml --branch <branch> --limit 5 --repo {{GITHUB_ORG}}/{{REPO_INFRA_NAME}}` — workflow 55 runs on PR, so a run should exist.
4. If no run: `gh workflow run 55-plan-modified-layers.yml --ref <branch> -f head_ref=<branch> -f root_layers="<root_layers>" -f env_layers="<env_layers>" --repo {{GITHUB_ORG}}/{{REPO_INFRA_NAME}}`, wait 60s, re-list.
5. `gh run watch <run_id> --repo {{GITHUB_ORG}}/{{REPO_INFRA_NAME}}` until completed.
6. `gh run download <run_id> --repo {{GITHUB_ORG}}/{{REPO_INFRA_NAME}} -D /tmp/plan-artifacts-<run_id>`.
7. Run `parse-plan-artifacts.sh` with workspace root paths.
8. Output report path and summary.

### Phase 3 — Final report

Write to `.cursor/bootstrap-align-reports/pipeline-{YYYY-MM-DD}-{jira_key}.md` (or `pipeline-{date}-pr{pr_number}.md` if no Jira key):

```markdown
# Infra Bootstrap Pipeline — {date}

## Phase 1: Alignment
- Jira: [link]
- PR: [link]
- Branch: [name]

## Phase 2: Plan validation
- Report: [path]
- Workflow run: [link]
- Summary: X create, Y update, Z delete, W replace
- Detailed table: Action | Resource | Description (modifications, impacted resources)

## Next steps
Review PR and plan. Merge manually when ready.
```

## Skill references

- Phase 1: `.cursor/skills/ops/infra-bootstrap-workflow/SKILL.md`
- Phase 2: `.cursor/skills/ops/infra-bootstrap-plan-validator/SKILL.md`
