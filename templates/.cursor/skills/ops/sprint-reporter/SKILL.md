---
name: sprint-reporter
description: Generates a sprint progress report from Jira and GitHub data. Summarizes tickets, PRs, velocity, blockers. On-demand trigger or integrated into dev-pipeline (optional weekly check).
---

# Sprint Reporter (Agent)

Workflow: fetch active sprint data from Jira → fetch recent PRs from GitHub → compute metrics → generate report → optionally notify via Teams.

## Trigger

- *"Generate sprint report"*
- *"Run sprint-reporter"*
- *"Sprint summary"*
- *"How is the current sprint going?"*

**Frequency**: On-demand. Run when you want a snapshot of sprint progress (e.g. weekly, at sprint review, or anytime).

## Rules

- **Language**: All outputs in **English**
- **Read-only**: Never modify Jira tickets or GitHub PRs
- **Reports dir**: `.cursor/sprint-reports/`

## Prerequisites

- Jira MCP available
- GitHub MCP available

## Workflow Steps

### 1. Fetch active sprint info

1. **Board ID**: Jira MCP `jira_get` path `/rest/agile/1.0/board` with `projectKeyOrId={{JIRA_PROJECT_KEY}}` → get `boardId` ({{JIRA_BOARD_ID}})
2. **Active sprint**: `jira_get` path `/rest/agile/1.0/board/{boardId}/sprint?state=active` → get sprint name, startDate, endDate, goal
3. **Sprint issues**: `jira_get` path `/rest/agile/1.0/sprint/{sprintId}/issue` with fields `summary,status,assignee,issuetype,story_points,updated,priority`

### 2. Categorize tickets

Group tickets by status category:

| Category | Status names |
|----------|-------------|
| Done | Done, Fermé, Closed |
| In Review | To Review, TO REVIEW |
| In Progress | In Progress, En cours |
| To Validate | To Validate, TO VALIDATE |
| To Do | To Do, À faire, Open |
| Blocked | Blocked, Bloqué |

Count tickets and story points per category.

### 3. Fetch GitHub PR data

For each repo, fetch PRs updated during the sprint period:

```
search_pull_requests query:"repo:{{GITHUB_ORG}}/{{REPO_BACK_NAME}} is:pr updated:>{sprint_start_date}" sort:updated order:desc perPage:10
search_pull_requests query:"repo:{{GITHUB_ORG}}/{{REPO_FRONT_NAME}} is:pr updated:>{sprint_start_date}" sort:updated order:desc perPage:10
search_pull_requests query:"repo:{{GITHUB_ORG}}/{{REPO_DATA_NAME}} is:pr updated:>{sprint_start_date}" sort:updated order:desc perPage:10
```

Categorize: merged, open, draft, closed without merge.

### 4. Compute metrics

| Metric | Formula |
|--------|---------|
| Sprint progress | Done tickets / Total tickets (%) |
| Story points completed | Sum of done story points / Total story points (%) |
| PRs merged | Count merged PRs per repo |
| PRs open/waiting | Count open PRs per repo |
| Avg lead time | Time from "In Progress" to "Done" for completed tickets |
| Blockers | Tickets with status "Blocked" or priority "Highest" |

### 5. Generate report

Write to `.cursor/sprint-reports/YYYY-MM-DD-sprint-report.md`:

```markdown
# Sprint Report — {sprint_name}

**Generated**: {date}
**Sprint period**: {start_date} → {end_date}
**Sprint goal**: {goal}

---

## Progress

| Category | Tickets | Story Points |
|----------|---------|-------------|
| Done | X | Y pts |
| In Review | X | Y pts |
| In Progress | X | Y pts |
| To Do | X | Y pts |
| Blocked | X | Y pts |
| **Total** | **X** | **Y pts** |

**Completion**: X% tickets, Y% story points

---

## PRs (this sprint)

### {{REPO_BACK_NAME}}
| PR | Title | Status | Author |
|----|-------|--------|--------|
| #XXX | ... | merged/open | ... |

### {{REPO_FRONT_NAME}}
| PR | Title | Status | Author |
|----|-------|--------|--------|
| #XXX | ... | merged/open | ... |

### {{REPO_DATA_NAME}}
| PR | Title | Status | Author |
|----|-------|--------|--------|

---

## Metrics

| Metric | Value |
|--------|-------|
| Sprint progress (tickets) | X% |
| Sprint progress (points) | Y% |
| PRs merged (total) | N |
| PRs open/waiting | N |
| Blockers | N |

---

## Blockers & Risks

| Ticket | Summary | Assignee | Status |
|--------|---------|----------|--------|
| {{JIRA_PROJECT_KEY}}-XXXX | ... | ... | Blocked |

---

## Highlights

- [Auto-generated key achievements from Done tickets]
- [Notable PRs merged]

---

## Next actions

- [Tickets still in To Do with high priority]
- [PRs waiting for review]
```

### 6. Output summary

Display a concise summary in chat and confirm report path.

## Integration with dev-pipeline (optional)

In dev-pipeline Phase 3 (notification), after the Teams message:

1. Check last sprint report date in `.cursor/sprint-reports/`
2. If no report exists or last report > 7 days: suggest running sprint-reporter
3. Do not auto-generate (leave it on-demand)

## Error handling

| Situation | Action |
|-----------|--------|
| No active sprint | Report "No active sprint found", list recent closed sprints |
| Jira MCP unavailable | Skip Jira data, generate GitHub-only report |
| GitHub MCP unavailable | Skip GitHub data, generate Jira-only report |
| No tickets in sprint | Generate empty report with note |
