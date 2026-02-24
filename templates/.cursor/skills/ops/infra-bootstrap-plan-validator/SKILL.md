---
name: infra-bootstrap-plan-validator
description: Validates Terraform plan output from infra-bootstrap PRs. Waits for workflow 55-plan-modified-layers, downloads artifacts, parses plan JSON, creates summary table in doc. Use when validating plan after infra-bootstrap-workflow or when user provides a PR/branch to validate.
---

# Infra Bootstrap Plan Validator (Agent)

Agent that validates Terraform plan output from an infra-bootstrap PR or branch. Runs after infra-bootstrap-workflow creates a PR, or when invoked manually with a PR number or branch name.

## How to launch

- *"Validate the Terraform plan for PR #XXX"*
- *"Run plan validator on branch feat/{{JIRA_PROJECT_KEY}}-XXXX-align-bootstrap-vX.Y.Z"*
- *"Execute infra-bootstrap-plan-validator for the last bootstrap align PR"*
- *"Check plan output and store summary for PR XXX"*

## Prerequisites

- `gh` CLI installed and authenticated
- Workspace includes `{{REPO_INFRA_NAME}}/`
- GitHub MCP available

## Inputs (optional, from infra-bootstrap-workflow)

When chained after infra-bootstrap-workflow, receive `root_layers` and `env_layers` (comma-separated layer names) from that skill's output. These are the layers actually modified by the align workflow. Pass them to workflow 55 so it plans only those layers instead of using git diff.

## Rules

- **Language**: All outputs and docs in **English**
- **Never** mention cursor, Cursor, AI, assistant or automation tools in commits or docs

## Workflow Steps

### 1. Resolve input (PR or branch)

If user provides PR number:
- `mcp_github_pull_request_read(method=get, owner={{GITHUB_ORG}}, repo={{REPO_INFRA_NAME}}, pullNumber=XXX)`
- Extract `head.ref` (branch) and `head.sha`

If user provides branch name:
- Use branch as head ref

If no input: search for latest open PR with title containing "Align infra with bootstrap" or "align-bootstrap":
- `mcp_github_search_pull_requests(query="repo:{{GITHUB_ORG}}/{{REPO_INFRA_NAME}} is:open align bootstrap")`

### 2. Find workflow run for 55-plan-modified-layers

```bash
cd {{REPO_INFRA_NAME}}
gh run list --workflow=55-plan-modified-layers.yml --branch <head_ref> --limit 5
```

If no run found, trigger via workflow_dispatch. When `root_layers` and `env_layers` are provided (from infra-bootstrap-workflow), pass them so the workflow plans only those layers:
```bash
gh workflow run 55-plan-modified-layers.yml --ref <head_ref> -f head_ref=<head_ref> -f root_layers="<comma_separated_root>" -f env_layers="<comma_separated_env>"
```
Example: `-f root_layers="03-appinsight,05_jumpbox" -f env_layers=""`. If no layers provided, omit those flags; workflow falls back to git diff.
Then wait 30s and re-run `gh run list`.

### 3. Wait for run completion

```bash
gh run watch <run_id> --repo {{GITHUB_ORG}}/{{REPO_INFRA_NAME}}
```

If `gh run watch` not available, poll until status is `completed`:
```bash
gh run view <run_id> --repo {{GITHUB_ORG}}/{{REPO_INFRA_NAME}} --json status,conclusion
```

### 4. Download artifacts

```bash
mkdir -p /tmp/plan-artifacts-<run_id>
gh run download <run_id> --repo {{GITHUB_ORG}}/{{REPO_INFRA_NAME}} -D /tmp/plan-artifacts-<run_id>
```

### 5. Parse artifacts and create report

Use the script:
```bash
bash .cursor/skills/ops/infra-bootstrap-plan-validator/scripts/parse-plan-artifacts.sh \
  /tmp/plan-artifacts-<run_id> \
  .cursor/bootstrap-align-reports/plan-summary-<YYYY-MM-DD>-pr<pr_number>.md \
  <pr_number> \
  <branch> \
  "https://github.com/{{GITHUB_ORG}}/{{REPO_INFRA_NAME}}/actions/runs/<run_id>"
```

Or parse manually: for each `json-files-{env}-{layer}/*.json`, read `resource_changes[]` with `address` and `change.actions[0]`, build markdown table.

### 6. Report doc path

`.cursor/bootstrap-align-reports/plan-summary-{YYYY-MM-DD}-pr{pr_number}.md`

The script generates: header (branch, run URL, date), summary table (env, layer, create/update/delete/replace counts), detailed table (Action | Resource | Description) for each impacted resource, with heuristic descriptions (e.g. "Extension version upgrade", "Replaced by for_each rules").

### 7. Output summary

- Report path
- Workflow run URL
- PR link
- Count of create/update/delete per environment
- Reminder: user must review plan before merge

## Integration with infra-bootstrap-workflow

Can be chained after infra-bootstrap-workflow: when infra-bootstrap creates a PR, invoke this skill with the PR number and the `root_layers` / `env_layers` from infra-bootstrap's output. This ensures workflow 55 plans only the layers actually modified by the align, not the git diff vs main.

## Error handling

- Workflow failed: report failure, link to run, do not create doc
- No artifacts: create doc with "No plan changes detected" or "Artifacts not available"
- No run found after 2 min: suggest manual workflow_dispatch
