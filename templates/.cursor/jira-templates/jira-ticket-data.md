# Jira Ticket Template — {{REPO_DATA_NAME}}

## Summary (required)

Prefix: **[DATA]** or **[Data Eng]**

Examples:
- `[Data Eng] Add integrity check to data ingestion pipeline`
- `[DATA] Improve file ingestion to save new field`
- `[Data Eng] Add new column to ETL pipeline`

---

## Description — Structure to follow

### Context / Problem

Describe the ingestion or pipeline need. Use domain vocabulary relevant to your project.

### File / data source

- File name or data source type
- Location: blob storage, container, path, database

### Data structure (if file-based ingestion)

Specify if:
- A new data source must be added
- An existing source must be modified
- Integrity validation is required

### Pipeline / impacted activity

- Module or service impacted
- Activity or service class name
- Execution order if multiple steps

### Schema / columns

- New columns to ingest
- Target table or data model
- Constraints (validation, primary key)

### Back migration (if applicable)

If a new column is added to the database: indicate whether {{REPO_BACK_NAME}} requires a SQL migration.

---

## Acceptance criteria checklist

- [ ] File or data source identified
- [ ] Data structure described
- [ ] Pipeline / module / activity impacted specified
- [ ] Schema or columns to add/modify described
- [ ] Integrity validation or expected error message if relevant
- [ ] Back migration mentioned if new column in database

---

## Technical references

- Stack: Python {{DATA_LANGUAGE_VERSION}}, {{DATA_PACKAGE_MANAGER}}, {{DATA_TEST_FRAMEWORK}}
- Structure: `{project_package}/` — organized by domain, services, infrastructure
- Pipelines: triggers → orchestrators → activities
