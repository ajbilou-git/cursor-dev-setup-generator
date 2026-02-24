# Jira Ticket Template — {{REPO_BACK_NAME}}

## Summary (required)

Prefix: **[BACK]**, **[API]** or **[SOFT]** depending on type.

Examples:
- `[BACK] Add cache for entity listing endpoint`
- `[API] Add filter parameter to search endpoint`
- `[SOFT] Refactor service layer for entity duplication`

---

## Description — Structure to follow

### Context / Problem

Describe the functional need or bug. Use domain vocabulary specific to your project.

### Expected behaviour

- What the API should return or the service should do
- Business rules (e.g. filter by specific criteria)
- Edge cases to handle

### Technical details (if relevant)

- Impacted endpoint(s): `GET /api/...`
- Entities/models involved
- Cache, timeout, pagination

### Subtasks (if cross-repo ticket)

If the ticket touches back + front, list:
- `[BACK]`: backend tasks
- `[FRONT]`: frontend tasks (create subticket or separate ticket)

---

## Acceptance criteria checklist

- [ ] Functional behaviour clearly described
- [ ] Impacted endpoints or services identified
- [ ] Business rules (filters, validations) explicit
- [ ] Error cases or edge cases mentioned if relevant
- [ ] Link to parent ticket or dependencies indicated if applicable

---

## Technical references

- Stack: {{BACK_FRAMEWORK}} {{BACK_FRAMEWORK_VERSION}}, {{BACK_LANGUAGE}} {{BACK_LANGUAGE_VERSION}}, {{BACK_BUILD_TOOL}}, {{BACK_DB_TYPE}}, Docker
- Structure: `api/`, `services/`, `models/`, repositories
- Patterns: DTO, mappers, cache, health `GET /api/actuator/health`
