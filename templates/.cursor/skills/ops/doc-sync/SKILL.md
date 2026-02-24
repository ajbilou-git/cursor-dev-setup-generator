---
name: doc-sync
description: Synchronizes {{PROJECT_NAME}} documentation from Confluence and MkDocs into .cursor/docs/ for RAG-like context enrichment. Fetches pages, converts to markdown, stores locally. Cursor codebase indexing makes content searchable via @Codebase.
---

# Doc Sync (Agent)

Workflow: fetch Confluence pages → fetch MkDocs pages → convert to markdown → store in `.cursor/docs/confluence/` and `.cursor/docs/mkdocs/` → update sync metadata.

## Trigger

- *"Sync documentation"*
- *"Run doc-sync"*
- *"Update local docs from Confluence"*
- *"Refresh documentation cache"*

## Rules

- **Language**: All outputs in **English**
- **Read-only on sources**: Never modify Confluence or MkDocs content
- **Overwrite local files only**: Replace `.cursor/docs/confluence/*.md` and `.cursor/docs/mkdocs/*.md`

## Prerequisites

- Confluence MCP available (for Confluence pages)
- Web fetch available (for MkDocs or public pages)
- Workspace includes `.cursor/docs/`

## Configuration

### Confluence pages to sync

| Page ID | Filename | Description |
|---------|----------|-------------|
| {{CONFLUENCE_PAGE_EP}} | ep-{{PROJECT_NAME_LOWER}}.md | EP - {{PROJECT_NAME}} (main page) |
| {{CONFLUENCE_PAGE_GDD}} | gdd.md | Global Design Document |
| {{CONFLUENCE_PAGE_ADD}} | add.md | Architecture Design Document |
| {{CONFLUENCE_PAGE_TECHDOC}} | technical-doc.md | Technical Documentation |

To add a new page: append a row to this table with the Confluence page ID, desired filename, and description.

### MkDocs pages to sync (optional)

If {{PROJECT_NAME}} has a MkDocs site, add URLs here:

| URL | Filename | Description |
|-----|----------|-------------|
| *(add MkDocs URLs when available)* | | |

## Workflow Steps

### 1. Prepare directories

```
mkdir -p .cursor/docs/confluence
mkdir -p .cursor/docs/mkdocs
```

### 2. Fetch Confluence pages

For each page in the configuration table:

1. Use Confluence MCP: `mcp_confluence_conf_get` with path `/wiki/api/v2/pages/{pageId}` and `body-format: view`
2. Extract the body content (HTML)
3. Convert HTML to clean markdown (strip Confluence macros, keep headings/tables/lists)
4. Write to `.cursor/docs/confluence/{filename}`

If a page fetch fails: log warning, skip that page, continue with others.

### 3. Fetch MkDocs pages (optional)

For each URL in the MkDocs configuration table:

1. Use `WebFetch` or `mcp_web_fetch` to retrieve the page
2. Extract main content (strip navigation, headers, footers)
3. Write to `.cursor/docs/mkdocs/{filename}`

If no MkDocs URLs configured: skip this step.

### 4. Update sync metadata

Write to `.cursor/docs/sync-metadata.json`:

```json
{
  "last_sync": "2026-02-19T14:30:00Z",
  "pages_synced": {
    "confluence": ["ep-{{PROJECT_NAME_LOWER}}.md", "gdd.md", "add.md", "technical-doc.md"],
    "mkdocs": []
  },
  "errors": []
}
```

### 5. Output summary

```
Doc Sync completed:
- Confluence: 4/4 pages synced
- MkDocs: 0 pages (none configured)
- Metadata: .cursor/docs/sync-metadata.json
- Last sync: 2026-02-19T14:30:00Z
```

## Integration with other skills

### dev-pipeline (optional)

Add to Phase 0a: after refreshing `functional-context.md`, check sync metadata. If `last_sync` > 7 days, run doc-sync automatically.

### dev-expert standalone

Step 0 (context refresh) can check sync metadata and suggest running doc-sync if stale.

### @Codebase queries

Once synced, all `.cursor/docs/confluence/*.md` files are indexed by Cursor's codebase indexing. Use `@Codebase` to search across documentation:
- "What is the MVP scope for {{PROJECT_NAME}}?"
- "What are the technical SLAs?"
- "How is the architecture designed?"

## Adding new pages

To sync additional Confluence pages:

1. Find the page ID in the Confluence URL (e.g. `{{JIRA_BASE_URL}}/wiki/spaces/{{CONFLUENCE_SPACE_KEY}}/pages/XXXXXXXXXX/PageTitle` → page ID is `XXXXXXXXXX`)
2. Add a row to the "Confluence pages to sync" table in this SKILL.md
3. Re-run doc-sync

## Error handling

| Situation | Action |
|-----------|--------|
| Confluence MCP unavailable | Skip Confluence sync, log error, continue with MkDocs |
| Page fetch returns 404 | Log warning, skip page, continue |
| HTML conversion fails | Store raw HTML as .html instead of .md, log warning |
| All pages fail | Report failure, do not update sync metadata |
