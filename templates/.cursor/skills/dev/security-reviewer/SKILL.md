---
name: security-reviewer
description: Security review agent for {{PROJECT_NAME}} PRs and code changes. Combines CodeRabbit, Trivy SARIF results, static analysis, and expert security review. Generates actionable security report. Use for PR security review or periodic security audit.
---

# Security Reviewer (Agent)

Workflow: identify scope (PR or branch) → run CodeRabbit → fetch Trivy SARIF results → static security analysis → expert review → generate security report.

## Trigger

- *"Security review PR #XXX"*
- *"Run security-reviewer on branch feat/{{JIRA_PROJECT_KEY}}-XXXX-..."*
- *"Security audit on {{REPO_BACK_NAME}}"*
- *"Review security of recent changes"*

**Input**: PR number, branch name, or repo name (for full audit).

## Rules

- **Language**: All outputs in **English**
- **Read-only on GitHub**: Do not modify PRs, issues, or code via GitHub MCP
- **Reports dir**: `.cursor/security-reports/`

## Prerequisites

- CodeRabbit CLI installed (`cr`)
- GitHub MCP available
- Target repo checked out locally

## Workflow Steps

### 1. Resolve scope

**If PR number provided**:
- Fetch PR via GitHub MCP: `pull_request_read(method=get, owner={{GITHUB_ORG}}, repo={repo}, pullNumber=XXX)`
- Checkout PR branch locally: `cd {repo} && git fetch origin && git checkout {head_ref}`
- Get list of modified files: `pull_request_read(method=get_files, ...)`

**If branch provided**:
- `cd {repo} && git checkout {branch} && git diff main...HEAD --name-only`

**If repo audit (no PR/branch)**:
- Scope = entire repo, focus on security-sensitive files (controllers, auth, config, secrets, Dockerfile, CI/CD)

### 2. CodeRabbit automated review

```
cd {repo}
coderabbit --prompt-only -t uncommitted
```

Parse output for security-related findings:
- Authentication/authorization issues
- Input validation gaps
- SQL injection, XSS, SSRF risks
- Hardcoded secrets or credentials
- Insecure dependencies

Do not run CodeRabbit more than 3 times for the same set of changes.

### 3. Fetch Trivy SARIF results (if available)

**For PRs**: Check GitHub security tab for SARIF uploads from the CI pipeline.

```
GitHub MCP: search_code query:"repo:{{GITHUB_ORG}}/{repo} path:trivy-results.sarif"
```

Or check the latest workflow run artifacts:
```
cd {repo}
gh run list --workflow=security.yml --branch {branch} --limit 1
gh run download {run_id} -n trivy-results --dir /tmp/trivy-{run_id}
```

Parse SARIF for CRITICAL and HIGH vulnerabilities. If no SARIF available, skip this step.

### 4. Static security analysis

Review modified files for common security patterns:

**{{REPO_BACK_NAME}} ({{BACK_LANGUAGE}}/{{BACK_FRAMEWORK}})**:
- Authentication/authorization annotations or middleware on new endpoints
- SQL queries: parameterized queries only, no string concatenation
- Input validation: proper validation on request bodies
- No wildcard CORS without restriction
- Secrets: no hardcoded passwords, API keys, tokens in source
- Dockerfile: no `USER root` in production, no secrets in build args
- Dependencies: check dependency files for known vulnerable versions

**{{REPO_FRONT_NAME}} ({{FRONT_FRAMEWORK}})**:
- No unsafe DOM manipulation or unsanitized user input rendering
- No security bypass calls without justification
- API calls: proper error handling, no token leakage in logs
- Environment/config files: no secrets in client-side configs

**{{REPO_DATA_NAME}} (Python)**:
- No `eval()`, `exec()`, `pickle.loads()` on untrusted input
- SQL: parameterized queries only, no f-string SQL
- No secrets in source or `.env` committed
- Dependencies: check dependency files for known CVEs

### 5. Expert security assessment

As a senior security reviewer, evaluate:

| Category | Check |
|----------|-------|
| **Authentication** | New endpoints protected? Auth bypass risks? |
| **Authorization** | Proper role checks? Privilege escalation? |
| **Input validation** | All user inputs validated? Proper types? |
| **Data exposure** | Sensitive data in responses? PII leakage? |
| **Injection** | SQL, NoSQL, LDAP, OS command injection? |
| **XSS/CSRF** | Frontend sanitization? CSRF tokens? |
| **Secrets** | Hardcoded secrets? Proper vault usage? |
| **Dependencies** | Known CVEs? Outdated packages? |
| **Docker** | Image base vulnerabilities? Non-root user? |
| **CI/CD** | Pipeline security? Secrets in logs? |

Severity levels: CRITICAL, HIGH, MEDIUM, LOW, INFO.

### 6. Generate report

Write to `.cursor/security-reports/YYYY-MM-DD-{repo}-security-review.md`:

```markdown
# Security Review — {repo}

**Date**: {date}
**Scope**: PR #{number} / branch {name} / full audit
**Reviewer**: Security Reviewer Agent

---

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | X |
| HIGH | X |
| MEDIUM | X |
| LOW | X |
| INFO | X |

**Verdict**: PASS / PASS WITH WARNINGS / FAIL

---

## Findings

### CRITICAL

| # | File | Finding | Recommendation |
|---|------|---------|----------------|
| 1 | path/to/file | Description | Fix suggestion |

### HIGH

| # | File | Finding | Recommendation |
|---|------|---------|----------------|

### MEDIUM

| # | File | Finding | Recommendation |
|---|------|---------|----------------|

---

## Trivy Results (container vulnerabilities)

| CVE | Package | Severity | Fixed Version |
|-----|---------|----------|---------------|
| CVE-XXXX-XXXXX | ... | CRITICAL | ... |

---

## CodeRabbit Findings

[Relevant security findings from CodeRabbit output]

---

## Recommendations

1. [Prioritized action items]
2. ...

---

## Checklist

- [ ] Authentication on all new endpoints
- [ ] Input validation on all user inputs
- [ ] No hardcoded secrets
- [ ] Dependencies up to date
- [ ] Docker image scanned
```

### 7. Output summary

Display findings summary in chat. If CRITICAL or HIGH issues found, flag them prominently.

## Integration with dev-pipeline

Can be invoked after dev-approval creates a PR:
1. In Phase 2, after push + PR creation
2. Run security-reviewer on the PR
3. Include security verdict in the Phase 3 report and Teams notification

To enable: add to dev-pipeline Phase 2 (after step 7):
```
Phase 2.5: Security review (optional)
  Run security-reviewer with PR number and target_repo
  Include verdict in Phase 3 report
```

## Error handling

| Situation | Action |
|-----------|--------|
| CodeRabbit not available | Skip CodeRabbit, run other checks |
| Trivy SARIF not found | Skip Trivy section, note in report |
| GitHub MCP unavailable | Analyze local files only |
| No security issues found | Generate report with PASS verdict |
