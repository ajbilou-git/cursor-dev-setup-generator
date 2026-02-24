---
name: dev-pipeline
description: Automated pipeline that runs dev-expert then dev-approval. Processes Jira tickets from all {{PROJECT_NAME}} repos (back, front, data). Implements, approval pushes and creates PR, writes report and notifies via Teams. Use when the user wants the full automated flow from ticket to approval.
---

# Dev Pipeline (Orchestrator)

Automated flow: **dev-expert** (implement + test + commit) → **dev-approval** (re-test + review) → **if REJECTED**: **dev-expert fix mode** (apply fixes) → **dev-approval** (re-review) → **notification** (report + chat + Teams).

**Fix loop**: Max 1 retry. If still rejected after the retry, stop and notify.

## Functional context

Before Phase 1, read both context files to understand the domain and product:

1. **`.cursor/docs/functional-context.md`** — domain vocabulary, recent PRs, recurring patterns, ticket routing
2. **`.cursor/skills/dev/dev-pipeline/confluence-context.md`** — {{PROJECT_NAME}} product context from Confluence (EP - {{PROJECT_NAME}}, GDD, MVP scope, environments, technical SLAs)

**Confluence MCP** (optional): Use `mcp_confluence_conf_get` to fetch additional pages when needed (e.g. GDD details, ADD, scoping cycles). Base URL: {{JIRA_BASE_URL}}/wiki/spaces/{{CONFLUENCE_SPACE_KEY}}/pages/{{CONFLUENCE_PAGE_EP}}/EP+-+{{PROJECT_NAME}}

## Repo routing (from ticket summary)

| Ticket prefix | Target repo(s) | Mode |
|---------------|-----------------|------|
| [BACK], [API] | {{REPO_BACK_NAME}} | single |
| [FRONT] | {{REPO_FRONT_NAME}} | single |
| [DATA], [Data Eng] | {{REPO_DATA_NAME}} | single |
| [SOFT] | {{REPO_BACK_NAME}} and/or {{REPO_FRONT_NAME}} | **analyzed** (Phase 0d) |
| [INFRA] or unclear | {{REPO_BACK_NAME}} (default) | single |

**[SOFT] tickets**: The agent does NOT blindly create two PRs. Phase 0d analyzes the ticket description, acceptance criteria, and codebase to determine which repos are actually impacted. A [SOFT] ticket may result in:
- **Back only** → single-repo mode (1 PR)
- **Front only** → single-repo mode (1 PR)
- **Both** → cross-repo mode (2 PRs, sequenced)

Pass `target_repo` (or `target_repos` list for cross-repo) to dev-expert and dev-approval.

## Critical: No manual steps

The agent MUST execute all commands directly. Never propose "Run manually" or "Run in Sandbox" — always run with `required_permissions: ["all"]` to avoid sandbox prompts. No human gate between phases.

**Cursor configuration (user)**: Pour un flux entièrement automatique sans approbation à chaque étape, configurer **Settings → Cursor Settings → Agents → Auto-Run** sur **"Run Everything"**. Sinon, l'agent sera bloqué à chaque commande (git, pytest, etc.).

## Commit messages

Never use "cursor", "agent", "IA" or similar in commit messages. Use neutral wording (e.g. "feat({{JIRA_PROJECT_KEY}}-1233): description").

## Prerequisites (before running)

| target_repo | Requirements |
|-------------|--------------|
| {{REPO_BACK_NAME}} | {{BACK_LANGUAGE}} {{BACK_LANGUAGE_VERSION}}, {{BACK_BUILD_TOOL}}, Docker Desktop running (if docker-compose). Ports {{BACK_PORT}}, {{BACK_DB_PORT}} free. |
| {{REPO_FRONT_NAME}} | Node.js, {{FRONT_BUILD_TOOL}}. `{{NPM_AUTH_TOKEN_VAR}}` exported (in `{{SHELL_CONFIG_FILE}}`) if private packages. |
| {{REPO_DATA_NAME}} | Python {{DATA_LANGUAGE_VERSION}}, {{DATA_PACKAGE_MANAGER}}. Optional: `.env` for integration tests. |

If install fails on {{REPO_FRONT_NAME}} with 401/403: `{{NPM_AUTH_TOKEN_VAR}}` is missing. User must add it to `{{SHELL_CONFIG_FILE}}` and restart.

## Handle environment failures

- **Tools not found**: Use `{{LOGIN_SHELL_CMD}} "cd {repo} && ..."` to load user environment.
- **{{REPO_FRONT_NAME}} install fails**: Use `{{LOGIN_SHELL_CMD}} "cd {{REPO_FRONT_NAME}} && {{FRONT_INSTALL_CMD}} && ..."` to load env vars from login shell.
- **Git pull fails** (SSH, access): Continue without pull. Create branch from current main. Do not block.
- **git push fails** (SSH Permission denied): Report in notification with status FAILED. Include the PR creation link `https://github.com/{owner}/{repo}/compare/main...{branch}` so the user can create the PR manually after pushing. User must configure SSH (see dev-local-setup.md) or use HTTPS remote. Never skip PR creation when push succeeds.
- **git status shows "no changes added"**: Always run `git add .` before `git commit`. Never skip staging.

## Branch creation (mandatory)

Before creating the feature branch, **always** run these commands in order:
```
cd {target_repo}
git checkout main
git pull origin main
git checkout -b feat/{{JIRA_PROJECT_KEY}}-XXXX-...
```
Use `required_permissions: ["all"]` for git commands. Never create the branch without pulling the latest main first.

## Trigger

Use this pipeline (not dev-expert alone) for full automation: Teams notification, PR creation, approval flow.

- *"Run the dev-pipeline"*
- *"Process ticket {{JIRA_PROJECT_KEY}}-1234 end-to-end"*
- *"Full pipeline: implement and approve {{JIRA_PROJECT_KEY}}-1234"*
- *"Automate dev-expert then dev-approval"*
- *"Refresh functional context"* — standalone: update `.cursor/docs/functional-context.md` only (no ticket processing)

**Input**: Ticket key (e.g. `{{JIRA_PROJECT_KEY}}-1234`) or leave empty to pick from sprint backlog.

## Workflow

### Phase 0a: Refresh functional context

**Always execute** at pipeline start. Use GitHub MCP and Jira MCP to fetch latest data, then overwrite `.cursor/docs/functional-context.md`.

**Confluence context**: Read `.cursor/skills/dev/dev-pipeline/confluence-context.md` for {{PROJECT_NAME}} product context (MVP scope, environments, SLAs). Optionally use Confluence MCP to fetch page details if needed (e.g. `mcp_confluence_conf_get` path `/wiki/api/v2/pages/{{CONFLUENCE_PAGE_EP}}` with `body-format: view`).

1. **GitHub** — merged PRs (8 per repo):
   - `search_pull_requests` repo:{{GITHUB_ORG}}/{{REPO_BACK_NAME}} is:merged, sort:updated, order:desc, perPage:8
   - `search_pull_requests` repo:{{GITHUB_ORG}}/{{REPO_FRONT_NAME}} is:merged, sort:updated, order:desc, perPage:8
   - `search_pull_requests` repo:{{GITHUB_ORG}}/{{REPO_DATA_NAME}} is:merged, sort:updated, order:desc, perPage:8

2. **Jira** — recent tickets (25):
   - Jira MCP `jira_get` path `/rest/api/3/search` (or `/rest/api/3/search/jql`), queryParams: jql=`project={{JIRA_PROJECT_KEY}} AND (sprint in closedSprints() OR sprint in openSprints()) ORDER BY updated DESC`, maxResults=`25`, fields=`summary,status,issuetype,updated`

3. **Regenerate** the markdown: keep sections 1 (vocabulaire), 4 (patterns), 5 (liens), 6 (consignes) unchanged. Replace sections 2 (PRs) and 3 (tickets) with fetched data. Update "Dernière mise à jour" to today (YYYY-MM-DD).

4. **Write** to `.cursor/docs/functional-context.md`.

**On API failure**: log warning, keep existing file, do not block pipeline.

**Standalone trigger** (*"Refresh functional context"*): execute Phase 0a only, then stop.

### Phase 0b: Cleanup closed ticket reports

Before processing the new ticket, remove dev-reports for tickets that are closed in Jira.

1. List all files in `.cursor/dev-reports/` matching `*_MM-*_result.md` (exclude README.md).
2. Extract unique ticket keys ({{JIRA_PROJECT_KEY}}-XXXX) from filenames using regex `MM-\d+`.
3. For each unique ticket key, query Jira: `GET /rest/api/3/issue/{key}` with `fields=status`. Use `jq` to get `fields.status.statusCategory.key`.
4. If `statusCategory.key == "done"` (ticket closed), delete all dev-report files containing that ticket key in their filename.
5. Use the `delete_file` tool for each file to remove.

**On Jira API failure**: skip that ticket, do not delete, continue with others. Do not block the pipeline.

### Phase 0c: Determine target repo(s)

Analyze the ticket summary. Extract prefix ([BACK], [FRONT], [DATA], [SOFT], etc.).

**Single-repo mode**: [BACK]/[API] → {{REPO_BACK_NAME}}, [FRONT] → {{REPO_FRONT_NAME}}, [DATA]/[Data Eng] → {{REPO_DATA_NAME}}, [INFRA]/unclear → {{REPO_BACK_NAME}}.

**Cross-repo candidate**: If prefix is **[SOFT]**, proceed to **Phase 0d: Scope analysis** to determine which repos are actually impacted. Do NOT assume both repos are needed.

### Phase 0d: Scope analysis ([SOFT] tickets only)

**Run only if** ticket prefix is [SOFT]. Analyze the ticket to determine which repos are actually impacted.

1. **Read ticket description and acceptance criteria** (from Jira, already fetched in Phase 1 step 1).

2. **Analyze impact** by looking for signals:

   | Signal | Repo impacted |
   |--------|---------------|
   | API endpoint changes, new/modified DTOs, service logic, ORM entities, SQL migration | {{REPO_BACK_NAME}} |
   | UI changes, new components, store modifications, routing, templates | {{REPO_FRONT_NAME}} |
   | Both signals present | both repos |

3. **Cross-reference with codebase**: if the ticket mentions specific entities, search both repos for those entities to confirm where changes are needed:
   - `grep -r "EntityName" {{REPO_BACK_NAME}}/src/ {{REPO_FRONT_NAME}}/src/` (example)
   - If entity exists in only one repo → single-repo mode for that repo

4. **Decision**:
   - If **only back** needs changes → `target_repos = ["{{REPO_BACK_NAME}}"]`, `cross_repo_mode = false`
   - If **only front** needs changes → `target_repos = ["{{REPO_FRONT_NAME}}"]`, `cross_repo_mode = false`
   - If **both** need changes → `target_repos = ["{{REPO_BACK_NAME}}", "{{REPO_FRONT_NAME}}"]`, `cross_repo_mode = true`

5. **Log the decision** in the report (Phase 3):
   ```
   Scope analysis ([SOFT] ticket):
   - Back impact: yes/no — reason: {brief justification}
   - Front impact: yes/no — reason: {brief justification}
   - Mode: single-repo ({repo}) / cross-repo (back + front)
   ```

### Phase 1: dev-expert

**If cross_repo_mode**: iterate over `target_repos` (back first, then front). For each repo, execute Phases 1+2 as a cycle. See "Cross-repo execution" below.

**Single-repo mode**: Execute dev-expert **in pipeline mode** with `target_repo`:
1. Get ticket (by key or from backlog)
2. Assign, analyze
3. **Before creating branch**: Run `cd {target_repo} && git checkout main && git pull origin main` (use `required_permissions: ["all"]`). Then create branch with `git checkout -b feat/{{JIRA_PROJECT_KEY}}-XXXX-...`. Never skip git pull.
4. Implement changes
5. Run tests (repo-specific) — use `required_permissions: ["all"]`
6. Commit locally (`git add .` then `git commit -S -m "..."`)

**Output to pass to Phase 2**: branch name, ticket key, target_repo, list of modified files (summary for report).

If dev-expert fails: stop, write report with status FAILED, send Teams notification, do not proceed.

### Cross-repo execution ([SOFT] tickets)

**Only triggered when Phase 0d determined `cross_repo_mode = true`** (both repos need changes). If Phase 0d determined only one repo is impacted, the pipeline runs in single-repo mode — no cross-repo execution.

When `cross_repo_mode = true`, the pipeline runs a cycle for each repo in `target_repos` sequentially:

**Cycle 1 — {{REPO_BACK_NAME}}**:
1. Phase 1 (dev-expert) with `target_repo={{REPO_BACK_NAME}}` → branch, implement backend changes, tests, commit
2. Phase 2 (dev-approval) with `is_fix_loop=false` → lint + CodeRabbit + expert review → push + PR

**Cycle 2 — {{REPO_FRONT_NAME}}**:
1. Phase 1 (dev-expert) with `target_repo={{REPO_FRONT_NAME}}` → branch, implement frontend changes, tests, commit
2. Phase 2 (dev-approval) with `is_fix_loop=false` → lint + CodeRabbit + expert review → push + PR

Each cycle is independent: if Cycle 1 fails, still attempt Cycle 2. Both PRs reference the same ticket key. Transition Jira to "To Review" only after both cycles complete (or after the last successful one).

Phase 3 (notification) consolidates results into a single report. If 2 PRs: Teams message with both links. If 1 PR: standard single-repo notification.

### Phase 2: dev-approval (automatic handoff)

As soon as Phase 1 completes, **immediately** run dev-approval with the branch name, ticket key, and target_repo.

Execute dev-approval with `is_fix_loop=false` (first pass — fast-track mode, skip redundant build/smoke since dev-expert already ran them):
1. Checkout the branch in target repo
2. Run lint/checkstyle only (build and smoke skipped in fast-track)
3. CodeRabbit automated review
4. Expert code review
5. **If APPROVED**: push branch, create PR via GitHub MCP → go to Phase 3
6. **If REJECTED**: go to Phase 2b (fix loop)

### Phase 2b: Fix loop (when REJECTED, max 1 retry)

**Only if** dev-approval rejected and this is the first rejection (attempt 1 of 2):

1. Invoke **dev-expert in fix mode** with:
   - **Input**: branch name, ticket key, target_repo, rejection context (list of required fixes)
   - **Task**: Apply the fixes. Re-run tests. Amend or new commit.

2. **Immediately** re-run dev-approval on the same branch with `is_fix_loop=true` (full test suite — code changed after fix).

3. **If APPROVED** (after fix): push, create PR → go to Phase 3.

4. **If REJECTED again**: stop, go to Phase 3 with status REJECTED. No more retries.

**If** this was already the second approval attempt: skip fix loop, go directly to Phase 3 with status REJECTED.

**Jira on rejection** (optional): When status is REJECTED (final), add a Jira comment. Skip if no-jira-write blocks it.

### Phase 3: Notification

When dev-approval finishes (approved or rejected after retry), produce the notification.

#### 3a. Report file

Write to `.cursor/dev-reports/YYYY-MM-DD_HHmm_{{JIRA_PROJECT_KEY}}-XXXX_result.md`:

```markdown
# Dev Pipeline — {date} {time}

## Ticket
- **Key**: {{JIRA_PROJECT_KEY}}-XXXX
- **Jira**: [link]
- **Repo**: {target_repo}
- **Branch**: feat/{{JIRA_PROJECT_KEY}}-XXXX-...
- **PR**: [link]

## Result
**Status**: APPROVED | REJECTED

## Changes (dev-expert)
[Summary of changes in global app context]

## Checks
| Check | Status |
|-------|--------|
| Lint/Checkstyle | OK / FAIL |
| Build | OK / FAIL |
| Smoke | OK / FAIL |
| Expert review | Approved / Rejected |

## Expert review (dev-approval)
[Summary of findings]

## Next steps
- If APPROVED: Review PR and merge when ready
- If REJECTED (after fix loop): [List of required fixes]. Re-run pipeline with same ticket to retry.
```

#### 3b. Chat summary (user notification)

Output a clear, scannable summary in the chat:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  DEV PIPELINE — COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Ticket: {{JIRA_PROJECT_KEY}}-XXXX
Repo: {target_repo}
Branch: feat/{{JIRA_PROJECT_KEY}}-XXXX-...
PR: [link]

Status: APPROVED / REJECTED

Changes: [Brief summary from dev-expert]

Checks: Lint OK | Build OK | Smoke OK | Expert review OK

Report: .cursor/dev-reports/YYYY-MM-DD_HHmm_{{JIRA_PROJECT_KEY}}-XXXX_result.md

Next: [Merge the PR] / [Fix the issues and re-run approval]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### 3c. Teams notification (mandatory)

**Always execute** the Teams notification. Read `TEAMS_WEBHOOK_URL` from `.cursor/skills/dev/dev-pipeline/.env`. The webhook posts to the channel configured in the URL (may differ from "Back Expert Agent").

**Execution** (run with `required_permissions: ["all"]` and `full_network`):

1. Source the env: `set -a && source .cursor/skills/dev/dev-pipeline/.env 2>/dev/null && set +a`
2. If `TEAMS_WEBHOOK_URL` is set, **run the script** (automatic, no manual step):

**Format (Office 365 Connector - sections with facts, no truncation)**:

```json
{
  "@type": "MessageCard",
  "@context": "https://schema.org/extensions",
  "themeColor": "{{TEAMS_COLOR_APPROVED}}",
  "summary": "Dev Pipeline {{JIRA_PROJECT_KEY}}-XXXX",
  "sections": [{
    "activityTitle": "Dev Pipeline — {{JIRA_PROJECT_KEY}}-XXXX",
    "activitySubtitle": "Status: APPROVED",
    "facts": [
      {"name": "Ticket", "value": "{{JIRA_PROJECT_KEY}}-XXXX"},
      {"name": "Repo", "value": "{{REPO_DATA_NAME}}"},
      {"name": "Branch", "value": "feat/{{JIRA_PROJECT_KEY}}-XXXX-full-branch-name"},
      {"name": "PR", "value": "https://github.com/{{GITHUB_ORG}}/{{REPO_DATA_NAME}}/pull/172"},
      {"name": "Résumé", "value": "Summary of the implemented changes"}
    ]
  }]
}
```

- Use `themeColor`: `{{TEAMS_COLOR_APPROVED}}` (blue) for APPROVED, `{{TEAMS_COLOR_REJECTED}}` (red) for REJECTED.
- **Branch**: full branch name, never truncate with "..."
- **PR**: full URL
- **Résumé**: concise one-line summary of changes, no truncation

**Command** (agent runs this automatically in Phase 3):
```bash
set -a && source .cursor/skills/dev/dev-pipeline/.env 2>/dev/null && set +a
./.cursor/skills/dev/dev-pipeline/teams_notify.sh {{JIRA_PROJECT_KEY}}-XXXX APPROVED {{REPO_DATA_NAME}} feat/{{JIRA_PROJECT_KEY}}-XXXX-branch-name "https://github.com/.../pull/172" "Résumé des changements"
```
Replace {{JIRA_PROJECT_KEY}}-XXXX, branch name, PR URL, and summary with actual values. Full values, no truncation.

If `.env` is missing or `TEAMS_WEBHOOK_URL` is empty: log a warning and continue. Do not fail the pipeline.

## Rules

- No human gate between Phase 1 and Phase 2. Handoff is automatic.
- If Phase 1 fails, do not run Phase 2. Report the failure and write a report file with status FAILED.
- Always write the report file, even on failure.
- Language: English.

## Resources

- Functional context: [.cursor/docs/functional-context.md](../../../docs/functional-context.md)
- Confluence context ({{PROJECT_NAME}}): [confluence-context.md](confluence-context.md)
- Confluence EP {{PROJECT_NAME}}: {{JIRA_BASE_URL}}/wiki/spaces/{{CONFLUENCE_SPACE_KEY}}/pages/{{CONFLUENCE_PAGE_EP}}/EP+-+{{PROJECT_NAME}}
- dev-expert: [SKILL.md](../dev-expert/SKILL.md)
- dev-approval: [SKILL.md](../dev-approval/SKILL.md)
- Reports: `.cursor/dev-reports/`
