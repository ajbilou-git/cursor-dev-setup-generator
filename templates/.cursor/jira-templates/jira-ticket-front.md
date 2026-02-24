# Jira Ticket Template — {{REPO_FRONT_NAME}}

## Summary (required)

Prefix: **[FRONT]**

Examples:
- `[FRONT] Filter dropdown field based on parent selection`
- `[FRONT] Create new entity store`
- `[FRONT] Add select-all and validate button on list page`

---

## Description — Structure to follow

### Context / Problem

Describe the user need or bug. Use domain vocabulary specific to your project.

### Expected behaviour (UI/UX)

- Page or component impacted
- Data displayed or filters applied
- User actions: buttons, selection, validation

### Data and stores

- Existing store to reuse or new store to create
- API to call (if new): back endpoint
- Data relationships and identifiers

### Subtasks (if cross-repo ticket)

If the ticket touches front + back, list:
- `[FRONT]`: frontend tasks
- `[BACK]`: backend tasks (create subticket or separate ticket)

---

## Acceptance criteria checklist

- [ ] Page/component concerned identified
- [ ] Store(s) to use or create specified
- [ ] Filters and data sources (API vs store) described
- [ ] Responsive behaviour or accessibility if relevant
- [ ] Design system ({{FRONT_DESIGN_SYSTEM}}) mentioned if new component

---

## Technical references

- Stack: {{FRONT_FRAMEWORK}} {{FRONT_FRAMEWORK_VERSION}}, TypeScript, npm
- Structure: `src/app/`, modules, services, models
- Routing: define main routes
