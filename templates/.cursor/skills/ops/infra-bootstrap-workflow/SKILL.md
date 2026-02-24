---
name: infra-bootstrap-workflow
description: Agent workflow to align {{REPO_INFRA_NAME}} with bootstrap-infra releases. Lists releases, compares PR changes with {{REPO_INFRA_NAME}}, creates a PR if needed.
---

# Infra Bootstrap Workflow (Agent)

Workflow: list bootstrap releases → fetch PR changes for each release → compare with {{REPO_INFRA_NAME}} → if different, create a PR to align.

## How to launch the workflow

Invoke the agent with one of these prompts (in chat or via @ skill):

- *"Run the infra bootstrap workflow"*
- *"Align {{REPO_INFRA_NAME}} with the latest bootstrap release"*
- *"Execute the infra-bootstrap-workflow skill"*
- *"Check if {{REPO_INFRA_NAME}} needs alignment with bootstrap and create a PR if so"*

The agent will follow the workflow steps below. Ensure the workspace includes `{{REPO_INFRA_NAME}}/` and that GitHub MCP + Jira MCP are available.

## Rules

- **Never** mention cursor, Cursor, AI, assistant or any automation tool in commits, PRs or Jira.
- **Language**: All comments, outputs and deliverables must be in **English** (Jira ticket, description, comments, changelog entries, PR title/body, GitHub comments).

## Jira ticket

**All fields in English**. **No PATCH** – use creation + dedicated endpoints only.

### 1. Create ticket

**POST** `/rest/api/3/issue`

Body (set everything at creation):
- `project`: `{"key": "{{JIRA_PROJECT_KEY}}"}`
- `summary`: `[DEVOPS] Align infra with bootstrap vX.Y.Z`
- `issuetype`: `{"name": "Tâche"}`
- `description`: ADF with text "Align {{REPO_INFRA_NAME}} with {{REPO_BOOTSTRAP_NAME}} vX.Y.Z. Reference: https://github.com/{{REPO_BOOTSTRAP_FULL}}/releases/tag/vX.Y.Z"

**Summary**: always `[DEVOPS] Align infra with bootstrap vX.Y.Z` (in brackets).

### 2. Assign to requester

**PUT** `/rest/api/3/issue/{issueKey}/assignee`

Body: `{"accountId": "<reporter_accountId>"}` — use `reporter.accountId` from the created issue, or `currentUser()` from `GET /rest/api/3/myself`.

### 3. Add to active sprint

1. **GET** `/rest/agile/1.0/board` with `projectKeyOrId={{JIRA_PROJECT_KEY}}` → get `boardId` (e.g. {{JIRA_BOARD_ID}}).
2. **GET** `/rest/agile/1.0/board/{boardId}/sprint?state=active` → get `sprintId`.
3. **POST** `/rest/agile/1.0/sprint/{sprintId}/issue` with body `{"issues": ["{{JIRA_PROJECT_KEY}}-XXXX"]}`.

### 4. Set parent {{JIRA_DEFAULT_PARENT_TICKET}} INFRA Cycle 5

At creation, add to body: `"parent": {"key": "{{JIRA_DEFAULT_PARENT_TICKET}}"}`. If create fails with parent, retry without it and set **manual** in Jira.

### If any step fails

Add comment (English): *"Manual actions required: Assign to requester, add to active sprint, set parent {{JIRA_DEFAULT_PARENT_TICKET}} INFRA Cycle 5."*

## Context

- **Bootstrap**: `{{REPO_BOOTSTRAP_FULL}}`
- **Target**: `{{GITHUB_ORG}}/{{REPO_INFRA_NAME}}` (workspace: `{{REPO_INFRA_NAME}}/`)
- **Reference aligned version**: first `## vX.Y.Z` section in `{{REPO_INFRA_NAME}}/docs/changelog.md`

## Workflow Steps

### 1. List bootstrap releases

```
GitHub MCP: list_releases(owner={{GITHUB_ORG}}, repo={{REPO_BOOTSTRAP_NAME}}, perPage=10)
```

### 2. Identify aligned version and releases to process

Read `{{REPO_INFRA_NAME}}/docs/changelog.md`. First `## vX.Y.Z` = aligned version.
Releases to process = those newer than aligned version.

### 3. For each target release

#### 3a. Fetch ALL modified files for each PR (mandatory)

For **each** PR in the release body, call:
```
GitHub MCP: pull_request_read(method=get_files, owner={{GITHUB_ORG}}, repo={{REPO_BOOTSTRAP_NAME}}, pullNumber=XXX)
```
This returns the **complete** list of modified files. **Do NOT skip any file.**

#### 3b. Pre-apply analysis (mandatory before any code change)

For **each** modified file in the PR:

1. **List** all code changes (patch/diff) from `get_files` result.
2. **Map** bootstrap path → project infra path (see 3e). If layer is absent → add to changelog "Not applied" and add comment to Jira ticket.
3. **Check existence**: does the equivalent file exist in {{REPO_INFRA_NAME}}?
4. **Check pertinence**: is the bootstrap change relevant and adapted to {{REPO_INFRA_NAME}} structure? (e.g. your project uses KV for secrets, bootstrap uses different pattern → do NOT blindly copy).
5. **Check bug applicability**: if the bootstrap change fixes a bug, verify whether that bug exists in your project. If your project has no such bug (e.g. bootstrap had path mismatch DORA vs dora, your project had consistent DORA) → **Not applied** with reason "bug fix not applicable: [reason]".
6. Document in changelog: "Applied" vs "Not applied" with reason (layer absent, different structure, not applicable, bug fix not applicable).

#### 3c. For EACH modified file (iterate over all files)

1. If pre-analysis says "Not applied" → skip, document in changelog only.
2. Fetch content in bootstrap at the release: `get_file_contents` with `ref=refs/tags/vX.Y.Z`
3. Determine equivalent path in {{REPO_INFRA_NAME}} using the path mapping (see 3e)
4. **If no equivalent layer/file exists** in your project infra **or structure is different** → **do NOT apply**; add to "Not applied" list and document in changelog only
5. Read the local file in {{REPO_INFRA_NAME}}
6. Compare: apply substitutions LZ_NAME → {{PROJECT_NAME}} on bootstrap content, then compare with your infra repo
7. If identical → skip
8. If different → add to list of changes to apply and apply the change

#### 3d. Non-applicable modifications

Modifications that are **not applicable** to {{REPO_INFRA_NAME}} must **not** be applied. **Only document** them in the changelog under "Not applied" with the reason. Examples:
- layer absent
- different structure
- **bug fix not applicable**: bootstrap fixes a bug that does not exist in your project (e.g. path mismatch in bootstrap vs consistent path in your project)

#### 3e. Path mapping (bootstrap → project infra) — Dynamic with validation

The path mapping is generated dynamically at runtime and validated before applying any changes.

**Step 3e.1: Generate dynamic mapping**

1. List bootstrap layers:
   - `GitHub MCP: get_file_contents(owner={{GITHUB_ORG}}, repo={{REPO_BOOTSTRAP_NAME}}, path=infrastructure/terraform/root, ref=refs/tags/vX.Y.Z)` → extract directory names
   - Same for `infrastructure/terraform/envs/`

2. List {{REPO_INFRA_NAME}} layers:
   - `ls {{REPO_INFRA_NAME}}/infrastructure/terraform/root/` → extract directory names
   - `ls {{REPO_INFRA_NAME}}/infrastructure/terraform/envs/`

3. Build mapping by matching bootstrap layer names to project infra layer names:
   - Exact match (e.g. `00_network` → `00_network`)
   - Known renames (from override table below)
   - Fuzzy match by number prefix or keyword (e.g. `03_appinsight` matches `03-appinsight`)
   - Unmatched bootstrap layers → candidate for "absent" or "new layer"
   - Unmatched project layers → project-only layers (never overwrite)

**Step 3e.2: Override table (known exceptions)**

This table contains confirmed mappings that cannot be inferred automatically:

| Bootstrap | Project infra | Status |
|-----------|-------------------|--------|
| `03_appinsight` | `03-appinsight` | rename |
| `06_grafana` | `07_grafana_devlake` | rename |
| `07_devlake` | `10_Devlake` | rename |
| `08_grafana_dashboards` | `09_grafana_dashboards` | rename |
| `50_environment_bootstrap` | — | absent (bootstrap-only) |
| `97_alerting` | — | absent (bootstrap-only) |
| `shared.variables` | `shared_variables` | rename |

**Step 3e.3: Identify and analyze new or renamed layers**

If a bootstrap layer exists that is NOT in the override table and NOT an exact match in {{REPO_INFRA_NAME}}, run a **contextual relevance analysis** before proposing anything.

**3e.3a: Fetch and analyze the bootstrap layer content**

For the new/unknown bootstrap layer:

1. Fetch all `.tf` files from the layer:
   `GitHub MCP: get_file_contents(owner={{GITHUB_ORG}}, repo={{REPO_BOOTSTRAP_NAME}}, path=infrastructure/terraform/root/{layer_name}, ref=refs/tags/vX.Y.Z)`

2. Extract from the Terraform code:
   - **Azure resources** deployed (e.g. `azurerm_application_insights`, `azurerm_container_group`, `azurerm_mysql_flexible_server`)
   - **Providers** required (azurerm, azapi, grafana, etc.)
   - **Variables** consumed (references to other layers, shared variables)
   - **Purpose**: what service/capability does this layer provision?

**3e.3b: Cross-reference with {{REPO_INFRA_NAME}} architecture**

Analyze {{REPO_INFRA_NAME}} to determine if the layer is relevant:

1. **Existing resources**: List all resource types used across {{REPO_INFRA_NAME}} layers:
   `grep -rh "resource \"azurerm_" {{REPO_INFRA_NAME}}/infrastructure/terraform/ | sort -u`

2. **Existing providers**: Read `versions.tf` files across {{REPO_INFRA_NAME}} layers to list active providers.

3. **Architecture patterns**: Check if {{REPO_INFRA_NAME}} uses the same services:

   | Bootstrap layer uses | {{PROJECT_NAME}} uses? | How to check |
   |---------------------|-------------------|--------------|
   | MySQL | MSSQL (not MySQL) | grep `azurerm_mssql` vs `azurerm_mysql` |
   | Redis | ? | grep `azurerm_redis. in project infra |
   | Container Apps | App Service | grep `azurerm_linux_web_app` vs `azurerm_container_app` |
   | AKS | Not used | grep `azurerm_kubernetes` |
   | Event Grid / Event Hub | ? | grep for event resources |
   | Application Gateway | Front Door | check `06_front_door` layer |

4. **Shared variable dependencies**: If the new layer references shared variables (e.g. `var.rg_name`, `var.kv_id`), verify those variables exist in your project's shared_variables/`.

**3e.3c: Build contextual recommendation**

Based on the analysis, classify the layer:

| Classification | Criteria | Recommendation |
|---------------|----------|----------------|
| **Relevant — direct match** | Layer deploys resources already used by your project (e.g. appinsight, keyvault) | Suggest mapping to closest existing layer |
| **Relevant — new capability** | Layer deploys a service your project could use (e.g. new monitoring, backup pattern) | Suggest creating new layer, flag for manual review |
| **Not relevant — different stack** | Layer deploys services your project does not use (e.g. MySQL, AKS, Container Apps) | Recommend marking as "absent" |
| **Ambiguous** | Cannot determine relevance automatically | Flag for user decision with full context |

**3e.3d: Present analysis and ask for validation**

**STOP and ask the user** with the full contextual analysis:

```
New bootstrap layer detected: {layer_name}

ANALYSIS:
  Purpose: {what the layer deploys, e.g. "Provisions Azure Container Apps with auto-scaling"}
  Azure resources: {list of azurerm_* resources}
  Providers: {azurerm, azapi, etc.}

PROJECT CONTEXT:
  Equivalent resources in project infra: {yes/no, list if yes}
  Shared variable dependencies met: {yes/no, missing vars if no}
  Architecture compatibility: {compatible / different stack / partial}

RECOMMENDATION: {Relevant / Not relevant / Ambiguous}
  Reason: {e.g. "{{PROJECT_NAME}} uses App Service (azurerm_linux_web_app), not Container Apps. This layer is not applicable."}

OPTIONS:
  1. Map to existing project infra layer: {suggest closest match if relevant}
  2. Create new layer in {{REPO_INFRA_NAME}} (requires your manual review after PR)
  3. Mark as "absent" — skip, bootstrap-only (recommended if not relevant)

Please choose (1/2/3) or provide custom mapping.
```

Similarly, if a known mapping target no longer exists in {{REPO_INFRA_NAME}} (renamed/deleted):
```
Known mapping target missing: {bootstrap_layer} → {expected_project_layer}
The layer {expected_project_layer} no longer exists in {{REPO_INFRA_NAME}}.

ANALYSIS:
  Closest existing layers: {list layers with similar prefix/keyword}
  Possible rename detected: {if a new layer name matches the pattern}

Please provide the new mapping or mark as absent.
```

**Step 3e.4: Confirm mapping before applying**

Before applying ANY changes (step 3c), display the complete resolved mapping to the user:

```
Resolved path mapping for vX.Y.Z:
| Bootstrap | Project infra | Source |
|-----------|-------------|--------|
| 00_network | 00_network | exact match |
| 03_appinsight | 03-appinsight | override table |
| 06_grafana | 07_grafana_devlake | override table |
| {new_layer} | ??? | NEW — user validation required |

Project infra-only layers (never overwrite):
- 06_front_door
- 00_network_mysql
- 90_project_monitoring

Proceed with this mapping? (yes/no/edit)
```

**Do not apply any changes until the user confirms the mapping.**

**Step 3e.5: Project infra-only layers (never overwrite)**

These layers exist only in {{REPO_INFRA_NAME}} and must never be modified by the align workflow:
- `06_front_door`
- `00_network_mysql`
- `90_project_monitoring`

If the dynamic scan detects additional project-only layers (no bootstrap equivalent), add them to this list automatically.

#### 3f. If changes are needed

1. Create Jira ticket (see "Jira ticket" section above):
   - POST create with summary `[DEVOPS] Align infra with bootstrap vX.Y.Z`
   - PUT assignee (reporter accountId)
   - POST add to active sprint
   - Parent {{JIRA_DEFAULT_PARENT_TICKET}} at creation or manual
2. Create branch: `feat/{{JIRA_PROJECT_KEY}}-XXXX-align-bootstrap-vX.Y.Z`
3. Apply all changes from step 3c (only applicable ones, per pre-analysis)
4. Update changelog: "Applied" and "Not applied" sections (English)
5. Build modified layers lists: from each applied file path, extract layer name. Root: `infrastructure/terraform/root/<layer>/` → add to `root_layers`. Env: `infrastructure/terraform/envs/<layer>/` → add to `env_layers`. Deduplicate, comma-separate.
6. Signed commit, push, create PR (title and body in English)

### 4. PR policy

**One PR per release**, not one PR per change.

## Required substitutions

- `[#LZ_NAME_UPPER#]` → `{{PROJECT_NAME}}`
- `[#LZ_NAME_LOWER#]` → project name (lowercase)

## Output summary (English)

- Jira ticket link
- PR link
- List of modified files
- **Modified layers** (for plan validator): comma-separated `root_layers` and `env_layers` from applied changes. Example: `root_layers=03-appinsight,05_jumpbox,07_grafana_devlake` and `env_layers=00_network`. Build this list from the project infra paths of files actually modified in step 3c (e.g. `infrastructure/terraform/root/03-appinsight/` → add `03-appinsight` to root_layers; `infrastructure/terraform/envs/00_network/` → add `00_network` to env_layers). Pass to infra-bootstrap-plan-validator.
- Reminder: user must review and merge manually
