# Dev Pipeline - Reference

## Flow

```
User: "Run dev-pipeline with {{JIRA_PROJECT_KEY}}-1234"
  → Phase 0a: Refresh functional context (GitHub PRs + Jira tickets → .cursor/docs/functional-context.md)
  → Phase 0b: Determine target repo from ticket ([BACK], [FRONT], [DATA])
  → Phase 1: dev-expert (implement, test, commit)
  → Phase 2: dev-approval (re-test, review)
    → If APPROVED: push + PR → Phase 3
    → If REJECTED: Phase 2b (fix loop)
  → Phase 2b (fix loop): dev-expert fix mode → dev-approval again
    → If APPROVED: push + PR → Phase 3
    → If REJECTED: Phase 3 (no more retries)
  → Phase 3: Report + Chat + Teams
```

## Repo routing

| Ticket prefix | Repo |
|---------------|------|
| [BACK], [API] | {{REPO_BACK_NAME}} |
| [FRONT] | {{REPO_FRONT_NAME}} |
| [DATA], [Data Eng] | {{REPO_DATA_NAME}} |
| [SOFT] | {{REPO_BACK_NAME}} and/or front (Phase 0d analysis) |
| [INFRA], unclear | {{REPO_BACK_NAME}} |

## Fix loop

Max 1 retry. When dev-approval rejects, dev-expert applies fixes, then re-approval runs. If still rejected, stop.

## Prerequisites (local env)

| Repo | Requirements |
|------|--------------|
| {{REPO_BACK_NAME}} | {{BACK_LANGUAGE}} {{BACK_LANGUAGE_VERSION}}, {{BACK_BUILD_TOOL}}, Docker running (if docker-compose). Ports {{BACK_PORT}}, {{BACK_DB_PORT}} free. |
| {{REPO_FRONT_NAME}} | Node.js, {{FRONT_BUILD_TOOL}}. `{{NPM_AUTH_TOKEN_VAR}}` in `{{SHELL_CONFIG_FILE}}` if private packages. |
| {{REPO_DATA_NAME}} | Python {{DATA_LANGUAGE_VERSION}}, {{DATA_PACKAGE_MANAGER}}. Optional: `.env` for integration tests. |

## No manual steps

All commands run with `required_permissions: ["all"]`. Never propose "Run manually" or "Run in Sandbox".

## Report file location

`.cursor/dev-reports/YYYY-MM-DD_HHmm_{{JIRA_PROJECT_KEY}}-XXXX_result.md`

## Branch creation (mandatory)

Before creating the feature branch: (1) `git checkout main`, (2) `git pull origin main`, (3) `git checkout -b feat/{{JIRA_PROJECT_KEY}}-XXXX-...`.

## Teams notification

Set `TEAMS_WEBHOOK_URL` in `.cursor/skills/dev/dev-pipeline/.env`.

## Functional context refresh

Standalone trigger: *"Refresh functional context"* — updates `.cursor/docs/functional-context.md` from GitHub (8 merged PRs per repo) and Jira (25 recent sprint tickets). No ticket processing.
