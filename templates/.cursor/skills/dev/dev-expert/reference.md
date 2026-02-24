# Dev Expert - Reference

## Jira Configuration

### Project
- **Key**: MM (EP - {{PROJECT_NAME}})
- **Board ID**: {{JIRA_BOARD_ID}}

### JQL pour tickets non assignés du sprint actif

```
project={{JIRA_PROJECT_KEY}} AND sprint in openSprints() AND assignee is EMPTY ORDER BY rank ASC
```

### Assignation

**PUT** `/rest/api/3/issue/{issueKey}/assignee`

Body: `{"accountId": "<accountId>"}`

Obtenir `accountId`: **GET** `/rest/api/3/myself` → champ `accountId`.

### Transitions de statut

**GET** `/rest/api/3/issue/{issueKey}/transitions` — lister les transitions disponibles.

**POST** `/rest/api/3/issue/{issueKey}/transitions`

Body: `{"transition": {"id": "<transitionId>"}}`

Transitions projet MM (IDs typiques) :
- In Progress (En cours) : 31 — à la prise du ticket
- To Review : 41 — après création de la PR

Si les IDs diffèrent, matcher par `to.name` dans la réponse GET.

### Restriction no-jira-write

Une exception existe pour le skill `dev-expert` dans `.cursor/rules/restrictions/no-jira-write.mdc`.

## Repos et commandes

### {{REPO_BACK_NAME}}
- Build: `{{BACK_LINT_CMD}} && {{BACK_BUILD_CMD}}`
- Smoke: `{{BACK_START_CMD}}`, health `http://localhost:{{BACK_PORT}}{{BACK_HEALTH_PATH}}`
- Stack: {{BACK_FRAMEWORK}} {{BACK_FRAMEWORK_VERSION}}, {{BACK_LANGUAGE}} {{BACK_LANGUAGE_VERSION}}, {{BACK_BUILD_TOOL}}, {{BACK_DB_TYPE}}, Docker

### {{REPO_FRONT_NAME}}
- Build: `{{FRONT_INSTALL_CMD}} && {{FRONT_LINT_CMD}} && {{FRONT_BUILD_CMD}}`
- Stack: {{FRONT_FRAMEWORK}} {{FRONT_FRAMEWORK_VERSION}}, {{FRONT_BUILD_TOOL}}

### {{REPO_DATA_NAME}}
- Build: `{{DATA_SETUP_CMD}} && {{DATA_TEST_CMD}}`
- Stack: Python {{DATA_LANGUAGE_VERSION}}, {{DATA_PACKAGE_MANAGER}}, {{DATA_TEST_FRAMEWORK}}

## Création de branche (obligatoire)

Avant de créer la branche feature : (1) `git checkout main`, (2) `git pull origin main`, (3) `git checkout -b feat/{{JIRA_PROJECT_KEY}}-XXXX-...`. Toujours s'assurer d'être sur main et à jour avant de créer la branche.

## Format de branche

- Feature: `feat/{{JIRA_PROJECT_KEY}}-XXXX-description-courte`
- Bugfix: `fix/{{JIRA_PROJECT_KEY}}-XXXX-description-courte`
- Kebab-case, pas d'espaces

## Commits signés

```bash
git commit -S -m "feat({{JIRA_PROJECT_KEY}}-XXXX): description"
```
