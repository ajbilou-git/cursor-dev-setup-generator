---
name: bootstrap-devops-expert
description: DevOps expert and technology watch for {{REPO_BOOTSTRAP_NAME}}. Fetches provider changelogs, analyzes code against deprecations/breaking changes, proposes improvements and best practices. Report includes a Cursor prompt (Appendix C) to apply suggested modifications. No comparison with other repos. Use when analyzing bootstrap, preparing releases, or seeking infrastructure improvements.
---

# Bootstrap DevOps Expert Agent

DevOps expert and technology watch dedicated to {{REPO_BOOTSTRAP_NAME}}. Workflow: clean previous report → fetch changelogs → analyze bootstrap code against changelog findings → technology watch → identify required modifications → produce clear report saved to `.cursor/bootstrap-devops-reports/`.

**Scope**: Bootstrap repo only. No comparison or interaction with other project repositories.

## How to launch

Invoke with one of these prompts:

- *"Run the bootstrap DevOps expert analysis"*
- *"Analyze the bootstrap infra and propose improvements"*
- *"Execute bootstrap-devops-expert skill"*
- *"Technology watch on bootstrap infra"*

Ensure workspace includes `{{REPO_BOOTSTRAP_NAME}}/`. GitHub MCP and web fetch required.

## Rules

- **Language**: All outputs in **English**.
- **Scope**: Bootstrap only. No comparison with other project repos.
- **Bootstrap repo**: GitHub MCP — **read-only only**.

## Workflow Steps

### 0. Clean previous report

**Mandatory** — before starting analysis, delete all existing report files in `.cursor/bootstrap-devops-reports/` (files matching `YYYY-MM-DD_*.md`). Ensures only the current run's report exists.

### 1. Fetch provider changelogs

**Mandatory** — fetch and parse changelogs for deprecations, breaking changes, removals:

- **azurerm**: `https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/CHANGELOG.md` — extract DEPRECATIONS, REMOVALS, BREAKING CHANGES, BUG FIXES for resources used in bootstrap
- **Terraform**: `https://github.com/hashicorp/terraform/releases` or changelog — major/minor changes
- **azapi**: `https://github.com/Azure/terraform-provider-azapi/releases` — if used
- **grafana provider**: `https://github.com/grafana/terraform-provider-grafana/releases` — if used

Use `mcp_web_fetch` or `WebSearch` to retrieve content.

### 2. Analyze bootstrap code against changelog

**Mandatory** — search bootstrap Terraform code for resources/attributes mentioned in changelog:

- **Deprecated resources/attributes**: grep for `azurerm_*`, `azapi_*`, `grafana_*` used in bootstrap; cross-check with changelog deprecations
- **Removed resources**: e.g. `azurerm_mobile_network*` removed in azurerm 4.57 — verify bootstrap does not use them
- **Breaking changes**: attributes renamed, required changes
- **Bug fixes**: if bootstrap uses affected resources, note the fix version

Produce a **Changes required** table: | Resource/File | Changelog finding | Action |

### 3. List bootstrap releases and scan codebase

- GitHub MCP: `list_releases`, `pull_request_read(method=get_files)` for recent releases
- Read: `versions.tf` in all layers, `docs/conventions.md`, `.github/workflows/` structure

### 4. Technology watch and best practices

- Latest provider versions vs bootstrap versions
- CI/CD: GitHub Actions best practices, OIDC, secrets vs vars
- Security: attestation, SBOM, ggshield
- IaC: drift prevention, naming, modularity

See [reference.md](reference.md) for checklists and changelog URLs.

### 5. Produce and save report

**Mandatory**: Write to `.cursor/bootstrap-devops-reports/YYYY-MM-DD_report-title-slug.md`

**Report format** — clear, scannable, actionable:

```markdown
# Bootstrap DevOps Analysis — [Date]

---

## Quick summary

| Priority | Count | Action |
|----------|-------|--------|
| Critical (changelog) | N | Fix before next release |
| High | N | Plan for next release |
| Medium | N | Backlog |
| Best practices | N | Adopt when possible |

---

## 1. Critical: Changelog-driven changes

### 1.1 Required modifications (from provider changelogs)

| File | Resource/Attribute | Changelog finding | Action |
|------|--------------------|-------------------|--------|
| path/to/file.tf | azurerm_xxx | Deprecated in 4.xx | Migrate to ... |
| ... | ... | ... | ... |

### 1.2 Deprecations to address

- [ ] Resource X — deprecated in Y, replace with Z
- [ ] Attribute A — use B instead

### 1.3 Removed resources (verify not used)

- azurerm_mobile_network* (removed 4.57) — bootstrap: [ ] not used

---

## 2. Version status

| Component | Bootstrap | Latest | Status |
|-----------|-----------|--------|--------|
| Terraform | x.x.x | x.x.x | OK / Upgrade |
| azurerm | x.x.x | x.x.x | OK / Upgrade |
| azapi | x.x.x | — | — |
| grafana | x.x.x | x.x.x | — |

---

## 3. Technology watch highlights

### 3.1 Provider updates (last 3–5 versions)

- **azurerm 4.60**: [key changes relevant to bootstrap]
- **azurerm 4.59**: [key changes]
- ...

### 3.2 Best practices to adopt

| Practice | Description | Where to apply |
|----------|-------------|----------------|
| X | ... | layers / workflows |
| Y | ... | ... |

---

## 4. Improvements (by priority)

### High

| # | Improvement | Affected area | Suggested action |
|---|-------------|---------------|------------------|
| 1 | ... | ... | ... |

### Medium

| # | Improvement | Affected area | Suggested action |
|---|-------------|---------------|------------------|

---

## 5. Release recommendations

- **Suggested version bump**: Terraform x.x, azurerm x.x
- **Breaking changes to document**: ...
- **Documentation updates**: conventions, changelog

---

## Appendix A: Bootstrap release history

| Release | Date | Key changes |
|---------|------|-------------|
| v4.1.0 | ... | ... |

---

## Appendix B: Changelog sources

- azurerm: https://github.com/hashicorp/terraform-provider-azurerm/blob/main/CHANGELOG.md
- Terraform: https://github.com/hashicorp/terraform/releases
- azapi: https://github.com/Azure/terraform-provider-azapi/releases

---

## Appendix C: Cursor prompt to apply changes

**Copy the block below and paste it into Cursor to apply the suggested modifications.**

```
Apply the following modifications to {{REPO_BOOTSTRAP_NAME}} based on this Bootstrap DevOps analysis report.

**Scope**: {{REPO_BOOTSTRAP_NAME}} repository only. Read-only for GitHub MCP (no create/update/delete).

**Git workflow** (before making changes):
1. Check if current branch is main; if not, run `git checkout main`
2. Run `git pull origin main`
3. Create a new branch: `feat/...` for new features or version upgrades, `fix/...` for fixes (e.g. `feat/terraform-azurerm-upgrade`, `fix/deprecation-migration`)

**Tasks** (in order of priority):

1. **Critical (changelog-driven)**: [List each modification from section 1.1 and 1.2 with file path, resource/attribute, and exact action]
2. **Version bumps**: [Update versions.tf in affected layers as per section 2]
3. **High-priority improvements**: [List from section 4 with file path and suggested action]
4. **Medium-priority** (optional): [List if space permits]

For each change:
- Edit the specified file(s)
- Follow Terraform best practices (fmt, naming conventions from docs/conventions.md)
- Do not add comments in code
- Verify no hardcoded values; use variables/tfvars
```
```

**Mandatory**: Always include Appendix C. Populate the prompt block with concrete content from sections 1.1, 1.2, 2, 4 (file paths, resource names, exact actions). If no actionable changes, use: "No critical or high-priority modifications identified. Review sections 2 (version status) and 4 (improvements) for optional updates."

After writing, confirm: "Report saved to `.cursor/bootstrap-devops-reports/YYYY-MM-DD_title.md`"

### 6. Optional: Deep-dive

If user asks for focus (e.g. "runner workflows", "Terraform versions"): narrow analysis and propose concrete changes (paths, snippets).

## Analysis checklist

- [ ] Previous reports deleted from `.cursor/bootstrap-devops-reports/`
- [ ] Changelogs fetched and parsed for deprecations/removals/breaking
- [ ] Bootstrap code searched for affected resources
- [ ] Changes required table populated
- [ ] Version alignment across layers verified
- [ ] Best practices section populated
- [ ] Report format: tables, clear sections, actionable items
- [ ] Appendix C (Cursor prompt) populated with concrete content from report findings

## Output

1. **Write** full report to `.cursor/bootstrap-devops-reports/YYYY-MM-DD_report-title-slug.md` (includes Appendix C with Cursor prompt)
2. **Confirm** file path to user
3. Optionally show short summary in chat
