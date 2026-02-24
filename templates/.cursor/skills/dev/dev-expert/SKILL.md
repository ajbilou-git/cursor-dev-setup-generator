---
name: dev-expert
description: Fully automated agent workflow to process a Jira ticket, implement changes in {{PROJECT_NAME}} repos (back, front, data), run local tests, push branch and create PR. Routes to the correct repo based on ticket type ([BACK], [FRONT], [DATA]). Use when the user provides a ticket key or wants to pick an unassigned ticket from the active sprint.
---

# Dev Expert (Agent)

Workflow: Get ticket → assign → analyze → determine target repo → create branch → implement → run tests → commit → push → create PR. Fully automated, no human validation gate.

## Trigger

- *"Run the dev-expert"*
- *"Process ticket {{JIRA_PROJECT_KEY}}-1234"*

**For full automation (Teams notification + PR + approval)**: Use **dev-pipeline** instead. dev-expert alone does not send Teams notifications.

- *"Implement {{JIRA_PROJECT_KEY}}-1234"*
- *"Pick an unassigned ticket from the sprint backlog and implement it"*

**Input**: The user can provide a ticket key (e.g. `{{JIRA_PROJECT_KEY}}-1234`) as input. If provided, use that ticket directly. If not, pick one from unassigned tickets in the active sprint.

**Target repo** (from ticket summary or pipeline input):
- [BACK], [API] → {{REPO_BACK_NAME}}
- [FRONT] → {{REPO_FRONT_NAME}}
- [DATA], [Data Eng] → {{REPO_DATA_NAME}}
- [SOFT] → {{REPO_BACK_NAME}} + {{REPO_FRONT_NAME}} (cross-repo, managed by dev-pipeline)
- [INFRA], unclear → {{REPO_BACK_NAME}} (default)

**Cross-repo ([SOFT])**: When invoked by dev-pipeline in cross-repo mode, `target_repo` is provided explicitly ({{REPO_BACK_NAME}} or {{REPO_FRONT_NAME}}). Focus implementation on that specific repo only. The pipeline handles sequencing both repos.

**Pipeline mode**: When invoked by dev-pipeline, STOP after step 9 (commit). Do NOT push, do NOT create PR. Output branch name, target_repo, list of modified files.

**Fix mode**: When invoked by dev-pipeline after a rejection, the input includes: branch name, ticket key, target_repo, rejection context. Skip steps 1–6 (do NOT run "Create the branch" — we're already on the feature branch). Start from step 7: apply the fixes, then run steps 8–9 (tests, commit). Output: updated list of modified files.

Workspace: `{{REPO_BACK_NAME}}/`, `{{REPO_FRONT_NAME}}/`, or `{{REPO_DATA_NAME}}/` depending on target. Jira MCP and GitHub MCP available.

**Commands**: ALWAYS use `required_permissions: ["all"]` for EVERY terminal command (tests, build, poetry, npm, gradle, git). Never propose manual execution. Sandbox prompts block the workflow.

## Functional context

Before analyzing a ticket, read `.cursor/docs/functional-context.md` to understand the domain vocabulary, recent PRs, and recurring patterns. This helps route correctly and implement consistently with existing code.

## Prerequisites (local env)

Before running tests, ensure the following are available:

| Repo | Requirements |
|------|--------------|
| {{REPO_BACK_NAME}} | {{BACK_LANGUAGE}} {{BACK_LANGUAGE_VERSION}}, {{BACK_BUILD_TOOL}}, Docker Desktop running (if docker-compose). Ports {{BACK_PORT}}, {{BACK_DB_PORT}} free. |
| {{REPO_FRONT_NAME}} | Node.js, {{FRONT_BUILD_TOOL}}. `{{NPM_AUTH_TOKEN_VAR}}` exported if private packages. Add to `{{SHELL_CONFIG_FILE}}` if missing. |
| {{REPO_DATA_NAME}} | Python {{DATA_LANGUAGE_VERSION}}, {{DATA_PACKAGE_MANAGER}}. Optional: `.env` in repo root for integration tests. |

For **{{REPO_FRONT_NAME}}**: use `{{LOGIN_SHELL_CMD}} "cd {{REPO_FRONT_NAME}} && {{FRONT_INSTALL_CMD}} && ..."` to load login shell and ensure env vars are available.

## Rules

- Never use "cursor", "agent", "IA" or similar in commit messages, PR titles, or Jira. Use neutral wording only.
- Language: English for commits, PR, Jira (description, comments).
- Commits: must be signed (`git commit -S -m "message"`).
- No direct push to `main`.

## Jira restriction

The `no-jira-write` rule forbids modifying existing tickets. Assigning a ticket is a modification. An exception exists for this workflow. See [reference.md](reference.md) section "Jira assign".

## Workflow steps

### 0. Quick context refresh (standalone only)

**Skip this step** if invoked by dev-pipeline (pipeline handles refresh in Phase 0a).

Check the "Dernière mise à jour" date in `.cursor/docs/functional-context.md`. If the date is older than 24 hours:

1. **GitHub** — fetch 3 latest merged PRs per repo:
   - `search_pull_requests` repo:{{GITHUB_ORG}}/{{REPO_BACK_NAME}} is:merged, sort:updated, order:desc, perPage:3
   - `search_pull_requests` repo:{{GITHUB_ORG}}/{{REPO_FRONT_NAME}} is:merged, sort:updated, order:desc, perPage:3
   - `search_pull_requests` repo:{{GITHUB_ORG}}/{{REPO_DATA_NAME}} is:merged, sort:updated, order:desc, perPage:3

2. **Jira** — fetch 10 recent tickets:
   - Jira MCP `jira_get` path `/rest/api/3/search`, queryParams: jql=`project={{JIRA_PROJECT_KEY}} AND sprint in openSprints() ORDER BY updated DESC`, maxResults=`10`, fields=`summary,status,issuetype,updated`

3. **Update** sections 2 (PRs) and 3 (tickets) in `.cursor/docs/functional-context.md`. Keep other sections unchanged. Update "Dernière mise à jour" to today.

If date is within 24 hours: skip, use existing context.

On API failure: log warning, keep existing file, continue to step 1.

### 1. Get the ticket

**If the user provided a ticket key**: fetch that ticket directly.

**If no ticket key was provided**: list unassigned tickets from the active sprint and pick the first one.

If no ticket found: inform the user and stop.

### 2. Assign the ticket to the requester

Use Jira MCP: `jira_put` `/rest/api/3/issue/{issueKey}/assignee` with `accountId` from `GET /rest/api/3/myself`.

### 2b. Transition to "In Progress"

Use Jira MCP: GET `/rest/api/3/issue/{issueKey}/transitions` to list available transitions. Find the transition whose `to.name` matches "En cours" or "In Progress" (or similar). POST `/rest/api/3/issue/{issueKey}/transitions` with body `{"transition": {"id": "<transitionId>"}}`. For project {{JIRA_PROJECT_KEY}}, transition ID {{JIRA_TRANSITION_IN_PROGRESS}} typically maps to "In Progress".

### 3. Analyze the ticket

Extract: title, description, acceptance criteria. Identify type (feature, bugfix, refactor), scope, entities involved.

### 4. Determine target repo

From ticket summary prefix: [BACK]/[API] → {{REPO_BACK_NAME}}, [FRONT] → {{REPO_FRONT_NAME}}, [DATA]/[Data Eng] → {{REPO_DATA_NAME}}. Default: {{REPO_BACK_NAME}}.

### 5. Analyze target repo code

Explore the structure of the target repo. Identify files to modify or create.

### 6. Create the branch

**MANDATORY sequence — never skip git pull:**

1. `cd {target_repo}`
2. `git checkout main`
3. `git pull origin main` — use `required_permissions: ["all"]` (network needed)
4. `git checkout -b feat/{{JIRA_PROJECT_KEY}}-XXXX-short-description`

Run these as separate commands or chained. If `git pull` fails (SSH, access): continue without pull, but still ensure we're on main before creating the branch.

Branch name: `feat/{{JIRA_PROJECT_KEY}}-XXXX-...` or `fix/{{JIRA_PROJECT_KEY}}-XXXX-...` depending on type.

### 7. Implement the changes

Apply the required code changes. Follow project conventions. Add tests when relevant. No comments (no-comments rule).

### 8. Run all tests locally (repo-specific)

**{{REPO_BACK_NAME}}**:
```
cd {{REPO_BACK_NAME}} && {{BACK_LINT_CMD}} && {{BACK_BUILD_CMD}}
cd {{REPO_BACK_NAME}} && {{BACK_START_CMD}}
```
Wait for containers (healthcheck start_period), then poll: `curl -s -o /dev/null -w "%{http_code}" http://localhost:{{BACK_PORT}}{{BACK_HEALTH_PATH}}` → expect 200.

**{{REPO_FRONT_NAME}}**:
```
{{LOGIN_SHELL_CMD}} "cd {{REPO_FRONT_NAME}} && {{FRONT_INSTALL_CMD}} && {{FRONT_LINT_CMD}} && {{FRONT_BUILD_CMD}}"
```
If `{{NPM_AUTH_TOKEN_VAR}}` is not in `{{SHELL_CONFIG_FILE}}`, install may fail on private packages. User must export the token first.

**{{REPO_DATA_NAME}}**:
```
cd {{REPO_DATA_NAME}} && {{DATA_SETUP_CMD}} && {{DATA_TEST_CMD}}
```

Use `{{LOGIN_SHELL_CMD}} "..."` if tools are not found. ALWAYS use `required_permissions: ["all"]` for ALL test/build commands to avoid sandbox approval prompts.

If any step fails: fix and retry. Do NOT proceed to commit until all pass.

### 9. Commit (automatic after all tests pass)

**Always run `git add .`** before commit.

```
cd {target_repo}
git add .
git status
git commit -S -m "feat({{JIRA_PROJECT_KEY}}-XXXX): concise description of the change"
```

Commit message: descriptive, neutral. No mention of tools or automation.

**Commit author**: Use only the repository user identity. Do not add Co-authored-by trailer. If GitHub shows "and Cursor" as co-author, the user must disable Cursor Settings → Features → Commit Attribution (search "co-author" in settings). See dev-local-setup.md.

**If in pipeline mode**: STOP here. Do not push, do not create PR. Output: branch name, target_repo, list of modified files.

**If standalone**: continue to step 10.

### 10. Push and Create PR (standalone only)

```
git push -u origin feat/{{JIRA_PROJECT_KEY}}-XXXX-short-description
```

Then create PR via GitHub MCP. Repo name = target_repo (e.g. {{REPO_BACK_NAME}}). Get owner from `mcp_github_get_me` or git remote.

### 10b. Transition to "To Review"

After PR creation, transition the Jira ticket to "To Review". GET `/rest/api/3/issue/{issueKey}/transitions`, find the transition whose `to.name` matches "TO REVIEW" or "To Review". POST `/rest/api/3/issue/{issueKey}/transitions` with body `{"transition": {"id": "<transitionId>"}}`. For project {{JIRA_PROJECT_KEY}}, transition ID {{JIRA_TRANSITION_TO_REVIEW}} typically maps to "To Review".

## Output summary

- Jira ticket key and link
- Target repo
- Branch created
- Files modified
- PR link (standalone only)

**When used in dev-pipeline**: Output branch name, target_repo, list of modified files (with brief summary for report), ticket key. Do NOT push or create PR.

## Resources

- Functional context: [.cursor/docs/functional-context.md](../../../docs/functional-context.md)
- Jira/GitHub details: [reference.md](reference.md)
- {{REPO_BACK_NAME}}: {{BACK_FRAMEWORK}} {{BACK_FRAMEWORK_VERSION}}, {{BACK_LANGUAGE}} {{BACK_LANGUAGE_VERSION}}, {{BACK_BUILD_TOOL}}, {{BACK_DB_TYPE}}, Docker
- {{REPO_FRONT_NAME}}: {{FRONT_FRAMEWORK}} {{FRONT_FRAMEWORK_VERSION}}, {{FRONT_BUILD_TOOL}}
- {{REPO_DATA_NAME}}: Python {{DATA_LANGUAGE_VERSION}}, {{DATA_TEST_FRAMEWORK}}
