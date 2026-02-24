# {{PROJECT_NAME}} — Contexte Confluence (EP - {{PROJECT_NAME}})

Document extrait de la documentation Confluence. Source : {{JIRA_BASE_URL}}/wiki/spaces/{{CONFLUENCE_SPACE_KEY}}/pages/{{CONFLUENCE_PAGE_EP}}/EP+-+{{PROJECT_NAME}}

**Dernière synchronisation** : (auto-updated by doc-sync)

---

## 1. {{PROJECT_NAME}} One Pager

(Brief description of the project — fill in from your Confluence EP page)

---

## 2. Key Dates (Product Lifecycle)

| Phase | Date(s) |
|-------|---------|
| (fill from your product lifecycle) | |

---

## 3. Environnements

| Environnement | URL |
|---------------|-----|
| Development | {{ENV_DEV_URL}} |
| Production | {{ENV_PROD_URL}} |

---

## 4. Structure documentation Confluence (arborescence)

- **EP {{PROJECT_NAME}}** — Main project page
  - [{{PROJECT_NAME}}] - GDD (Product Overview, Scope, Tech Overview)
  - [{{PROJECT_NAME}}] - ADD (Architecture)
  - [{{PROJECT_NAME}}] Build — Sprint Reviews, Technical Docs, Functional Docs
  - [{{PROJECT_NAME}}] DevOps — CI/CD, Infrastructure, Security

---

## 5. MVP Scope (GDD — key modules)

| Module | Cycle | Target |
|--------|-------|--------|
| (fill from your GDD) | | |

---

## 6. Technical SLAs (GDD)

| Component | Metric | Target |
|-----------|--------|--------|
| (fill from your GDD) | | |

---

## 7. Key Integrations

| Source | Business impact | Priority |
|--------|-----------------|----------|
| (fill from your architecture docs) | | |

---

## 8. Usage by dev-pipeline agent

Before Phase 1 (dev-expert), the agent should:

1. Read `.cursor/docs/functional-context.md` (local functional context)
2. Read this file `confluence-context.md` for {{PROJECT_NAME}} product context
3. Optional: use Confluence MCP to fetch specific pages for more detail (e.g. GDD, ADD)

**Confluence MCP**: `mcp_confluence_conf_get` with path `/wiki/api/v2/pages/{id}` and `body-format: view` for content.

**Useful Confluence pages**:
- EP {{PROJECT_NAME}} : {{CONFLUENCE_PAGE_EP}}
- GDD : {{CONFLUENCE_PAGE_GDD}}
- ADD : {{CONFLUENCE_PAGE_ADD}}
- Technical Documentation : {{CONFLUENCE_PAGE_TECHDOC}}
