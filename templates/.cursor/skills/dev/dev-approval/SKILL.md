---
name: dev-approval
description: Agent that reviews modifications from dev-expert, re-runs all local tests, verifies code quality and approves changes as a senior expert. Supports {{REPO_BACK_NAME}}, {{REPO_FRONT_NAME}}, {{REPO_DATA_NAME}}. Use when the user wants to validate, re-test and approve changes before merge.
---

# Dev Approval (Agent)

Review agent: takes dev-expert modifications as input → re-runs tests locally → verifies code quality → approves or rejects as senior expert.

## Trigger

- *"Review and approve the dev-expert changes"*
- *"Re-test and approve the modifications"*
- *"Run dev-approval"*
- *"Validate the changes"*

**Functional context**: Before reviewing, read `.cursor/docs/functional-context.md` (domain vocabulary, patterns) and `.cursor/skills/dev/dev-pipeline/confluence-context.md` ({{PROJECT_NAME}} product context). This helps assess correctness and consistency with product scope and SLAs.

**Input**: The modifications from dev-expert. Typically:
- A branch name (e.g. `feat/{{JIRA_PROJECT_KEY}}-1234-add-feature`) — **when called by dev-pipeline, the branch is provided**
- A target repo ({{REPO_BACK_NAME}}, {{REPO_FRONT_NAME}}, {{REPO_DATA_NAME}})
- A ticket key (e.g. {{JIRA_PROJECT_KEY}}-1234) — extract from branch name if not provided
- A PR number or current working directory state
- `is_fix_loop` (boolean, default false) — set to true when this is a re-review after dev-expert fix mode

If the user provides a branch or PR, checkout that branch first. If not specified, use the current branch or working tree.

**When used in dev-pipeline**: After approval, push the branch and create PR automatically. Never propose manual push or PR.

**Fast-track mode** (skip redundant tests): When `is_fix_loop` is false and this is the first approval pass after dev-expert, dev-expert already ran the full test suite (checkstyle/lint + build + smoke). In this case, skip steps 3 (full build) and 4 (smoke test) and only run step 2 (lint/checkstyle) + step 4.5 (CodeRabbit) + step 5 (expert review). When `is_fix_loop` is true, run ALL steps (2, 3, 4, 4.5, 5) since code changed after the fix.

**Commands**: ALWAYS use `required_permissions: ["all"]` for EVERY terminal command (gradle, npm, poetry, pytest, git). Use `full_network` for push/PR. Sandbox prompts block the workflow.

Workspace: `{{REPO_BACK_NAME}}/`, `{{REPO_FRONT_NAME}}/`, or `{{REPO_DATA_NAME}}/` depending on target.

## Prerequisites (local env)

| Repo | Requirements |
|------|--------------|
| {{REPO_BACK_NAME}} | {{BACK_LANGUAGE}} {{BACK_LANGUAGE_VERSION}}, {{BACK_BUILD_TOOL}}, Docker Desktop running (if docker-compose). Ports {{BACK_PORT}}, {{BACK_DB_PORT}} free. |
| {{REPO_FRONT_NAME}} | Node.js, {{FRONT_BUILD_TOOL}}. `{{NPM_AUTH_TOKEN_VAR}}` in `{{SHELL_CONFIG_FILE}}` if private packages. Use `{{LOGIN_SHELL_CMD}} "..."` for commands. |
| {{REPO_DATA_NAME}} | Python {{DATA_LANGUAGE_VERSION}}, {{DATA_PACKAGE_MANAGER}}. Optional: `.env` for integration tests. |

## Rules

- Act as a senior fullstack expert: strict on quality, security, conventions.
- Language: English for all outputs.
- Approval means: all checks pass and code meets expert standards.

## Workflow steps

### 1. Get the modifications

**If branch or PR provided**: `cd {target_repo}`, then `git fetch origin`, `git checkout {branch-name}`, and get the diff vs main.

**If current state**: use `git status`, `git diff` to see changes.

List all modified and new files. Understand the scope of changes.

### 2. Run lint/checkstyle (repo-specific)

**{{REPO_BACK_NAME}}**: `cd {{REPO_BACK_NAME}} && {{BACK_LINT_CMD}}`

**{{REPO_FRONT_NAME}}**: `{{LOGIN_SHELL_CMD}} "cd {{REPO_FRONT_NAME}} && {{FRONT_INSTALL_CMD}} && {{FRONT_LINT_CMD}}"`

**{{REPO_DATA_NAME}}**: `cd {{REPO_DATA_NAME}} && {{DATA_LINT_CMD}}`

If it fails: report violations, do not approve. List the issues.

### 3. Run full build (repo-specific) — SKIP in fast-track mode

**Skip this step** if `is_fix_loop` is false (first pass — dev-expert already ran the full build).

**Run this step** if `is_fix_loop` is true (code changed after fix).

**{{REPO_BACK_NAME}}**: `cd {{REPO_BACK_NAME}} && {{BACK_BUILD_CMD}}`

**{{REPO_FRONT_NAME}}**: `{{LOGIN_SHELL_CMD}} "cd {{REPO_FRONT_NAME}} && {{FRONT_BUILD_CMD}}"`

**{{REPO_DATA_NAME}}**: `cd {{REPO_DATA_NAME}} && {{DATA_TEST_CMD}}`

If it fails: report the error, do not approve.

### 4. Run smoke test (repo-specific) — SKIP in fast-track mode

**Skip this step** if `is_fix_loop` is false (first pass — dev-expert already ran the smoke test).

**Run this step** if `is_fix_loop` is true (code changed after fix).

**{{REPO_BACK_NAME}}**: `cd {{REPO_BACK_NAME}} && {{BACK_START_CMD}}`, then poll `http://localhost:{{BACK_PORT}}{{BACK_HEALTH_PATH}}` → expect 200.

**{{REPO_FRONT_NAME}}**: `{{FRONT_START_CMD}}` or serve build, verify app loads.

**{{REPO_DATA_NAME}}**: Skip or run integration tests if applicable.

If not 200 or failing: do not approve. Report the failure.

### 4.5. CodeRabbit automated review

Run CodeRabbit on the uncommitted/staged changes to get an automated review:

```
cd {target_repo}
coderabbit --prompt-only -t uncommitted
```

Parse CodeRabbit output and integrate findings into the expert review (step 5). Flag any critical or high-severity issues found by CodeRabbit as blocking.

Do not run CodeRabbit more than 3 times for the same set of changes.

### 5. Expert code review

As a senior fullstack expert, review the changes for:

- **Correctness**: logic, edge cases, error handling
- **Security**: no sensitive data, proper validation, no injection risks
- **Conventions**: naming, structure, no comments (no-comments rule)
- **Tests**: adequate coverage for new/changed code
- **Performance**: no obvious bottlenecks
- **Maintainability**: clear, readable, follows project patterns

Read the modified files. Apply expert judgment. Note any concerns.

### 6. Approval decision

**Approve** if: All steps 2, 3, 4 pass and expert review (step 5) finds no blocking issues.

**Reject** if: Any test fails or expert review finds blocking issues (security, correctness, major convention violations).

### 7. If APPROVED: Push and create PR

**When used in dev-pipeline** and status is APPROVED, execute immediately:

```
cd {target_repo}
git push -u origin {branch-name}
```

Then create PR via GitHub MCP. Repo = target_repo (e.g. {{REPO_BACK_NAME}}). Get owner from git remote or `mcp_github_get_me`.

Use `required_permissions: ["all"]` and `full_network` for git push.

**If push fails** (SSH Permission denied): Do not block. Output to pipeline: push failed, PR creation link for manual recovery: `https://github.com/{owner}/{repo}/compare/main...{branch-name}`. The user can push manually then open this URL to create the PR. Include this link in the Teams notification.

### 7b. Transition Jira to "To Review"

After PR creation, transition the Jira ticket to "To Review". Extract ticket key from branch name (e.g. feat/{{JIRA_PROJECT_KEY}}-1234-... → {{JIRA_PROJECT_KEY}}-1234) or use provided ticket key. GET `/rest/api/3/issue/{issueKey}/transitions`, find the transition whose `to.name` matches "TO REVIEW" or "To Review". POST `/rest/api/3/issue/{issueKey}/transitions` with body `{"transition": {"id": "<transitionId>"}}`. For project {{JIRA_PROJECT_KEY}}, transition ID {{JIRA_TRANSITION_TO_REVIEW}} typically maps to "To Review".

### 8. Output

**If approved**:
```
## Dev Expert Approval

- Lint/Checkstyle: OK
- Build: OK
- Smoke: OK
- Code review: Approved
- Push: OK
- PR: [link]

The modifications meet expert standards. Safe to merge.
```

**If rejected**:
```
## Dev Expert Rejection

- [List failed checks and reasons]
- [Expert review findings]

Action required: [specific fixes needed]
```

**When used in dev-pipeline**: Output status (APPROVED/REJECTED), check results, expert review summary, PR link (if approved). Pipeline builds report and sends Teams notification.

## Environment

Use login shell for tools: `{{LOGIN_SHELL_CMD}} "..."`. Use `required_permissions: ["all"]` for Docker.

## Resources

- Functional context: [.cursor/docs/functional-context.md](../../../docs/functional-context.md)
- Confluence context: [.cursor/skills/dev/dev-pipeline/confluence-context.md](../dev-pipeline/confluence-context.md)
- Test commands: see dev-expert [reference.md](../dev-expert/reference.md)
- {{REPO_BACK_NAME}}: {{BACK_FRAMEWORK}} {{BACK_FRAMEWORK_VERSION}}, {{BACK_LANGUAGE}} {{BACK_LANGUAGE_VERSION}}, {{BACK_BUILD_TOOL}}, {{BACK_DB_TYPE}}, Docker
- {{REPO_FRONT_NAME}}: {{FRONT_FRAMEWORK}} {{FRONT_FRAMEWORK_VERSION}}, {{FRONT_BUILD_TOOL}}
- {{REPO_DATA_NAME}}: Python {{DATA_LANGUAGE_VERSION}}, {{DATA_TEST_FRAMEWORK}}
